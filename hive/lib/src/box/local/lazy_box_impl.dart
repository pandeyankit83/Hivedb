// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/local/local_box_base_impl.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:hive/src/hive_impl.dart';

class LazyBoxImpl<E> extends LocalBoxBaseImpl<E> implements LazyBox<E> {
  LazyBoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
  ) : super(hive, name, keyComparator, compactionStrategy, backend);

  @override
  final bool isLazy = true;

  @override
  Future<E> get(dynamic key, {E defaultValue}) async {
    checkOpen();

    var frame = keystore.get(key);

    if (frame != null) {
      var value = await backend.readValue(frame);
      if (value is HiveObject) {
        value.init(key, this);
      }
      return value as E;
    } else {
      return defaultValue;
    }
  }

  @override
  Future<E> getAt(int index) {
    return get(keystore.keyAt(index));
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> entries,
      {Iterable<dynamic> keysToDelete}) async {
    checkOpen();

    var frames = <Frame>[];

    if (keysToDelete != null) {
      for (var key in keysToDelete) {
        if (keystore.containsKey(key)) {
          frames.add(Frame.deleted(key));
        }
      }
    }

    for (var key in entries.keys) {
      frames.add(Frame(key, entries[key]));
      if (key is int) {
        keystore.updateAutoIncrement(key);
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames);

    for (var frame in frames) {
      if (frame.deleted) {
        keystore.insert(frame);
      } else {
        if (frame.value is HiveObject) {
          (frame.value as HiveObject).init(frame.key, this);
        }
        keystore.insert(frame.toLazy());
      }
    }

    await performCompactionIfNeeded();
  }
}
