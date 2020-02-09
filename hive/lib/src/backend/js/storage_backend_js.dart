import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/indexed_db.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:meta/meta.dart';

class StorageBackendJs extends StorageBackend {
  static const bytePrefix = [0x90, 0xA9];
  static const storeName = 'box';
  final Database db;
  final HiveCipher cipher;

  TypeRegistry _registry;

  StorageBackendJs(this.db, this.cipher, [this._registry]);

  @override
  String get path => null;

  @override
  bool supportsCompaction = false;

  bool _isEncoded(Uint8List bytes) {
    return bytes.length >= bytePrefix.length &&
        bytes[0] == bytePrefix[0] &&
        bytes[1] == bytePrefix[1];
  }

  @visibleForTesting
  dynamic encodeValue(Frame frame) {
    var value = frame.value;
    if (cipher == null) {
      if (value == null) {
        return value;
      } else if (value is Uint8List) {
        if (!_isEncoded(value)) {
          return value.buffer;
        }
      } else if (value is num || value is bool || value is String) {
        return value;
      }
    }

    var frameWriter = BinaryWriterImpl(_registry);
    frameWriter.writeByteList(bytePrefix, writeLength: false);

    if (cipher == null) {
      frameWriter.write(value);
    } else {
      frameWriter.writeEncrypted(value, cipher);
    }

    var bytes = frameWriter.toBytes();
    var sublist = bytes.sublist(0, bytes.length);
    return sublist.buffer;
  }

  @visibleForTesting
  dynamic decodeValue(dynamic value) {
    if (value is ByteBuffer) {
      var bytes = Uint8List.view(value);
      if (_isEncoded(bytes)) {
        var reader = BinaryReaderImpl(bytes, _registry);
        reader.skip(2);
        if (cipher == null) {
          return reader.read();
        } else {
          return reader.readEncrypted(cipher);
        }
      } else {
        return bytes;
      }
    } else {
      return value;
    }
  }

  @pragma('dart2js:tryInline')
  @visibleForTesting
  ObjectStore getStore(bool write) {
    return db.getStore(storeName, write);
  }

  @override
  Future<int> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    _registry = registry;
    var store = getStore(false);
    var keys = await store.getAllKeys();
    if (!lazy) {
      var i = 0;
      var values = await store.getAllValues();
      for (var value in values) {
        var key = keys[i++];
        var decoded = decodeValue(value);
        keystore.insert(Frame(key, decoded), notify: false);
      }
    } else {
      for (var key in keys) {
        keystore.insert(Frame.lazy(key), notify: false);
      }
    }

    return 0;
  }

  @override
  Future<dynamic> readValue(Frame frame) async {
    var value = await getStore(false).get(frame.key);
    return decodeValue(value);
  }

  @override
  Future<void> writeFrames(List<Frame> frames) async {
    var store = getStore(true);
    for (var frame in frames) {
      if (frame.deleted) {
        await store.delete(frame.key);
      } else {
        await store.put(frame.key, encodeValue(frame));
      }
    }
  }

  @override
  Future<List<Frame>> compact(Iterable<Frame> frames) {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> clear() {
    return getStore(true).clear();
  }

  @override
  Future<void> close() {
    db.close();
    return Future.value();
  }

  @override
  Future<void> deleteFromDisk() {
    return db.delete();
  }
}
