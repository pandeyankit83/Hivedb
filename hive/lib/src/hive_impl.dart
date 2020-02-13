import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/adapters/duration_adapter.dart';
import 'package:hive/src/backend/storage_backend_memory.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/box/isolate/isolate_box_impl.dart';
import 'package:hive/src/box/local/box_impl.dart';
import 'package:hive/src/box/local/lazy_box_impl.dart';
import 'package:hive/src/util/extensions.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

import 'backend/storage_backend.dart';

class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  final _boxes = HashMap<String, BoxBaseImpl>();
  final BackendManager _manager;
  final Random _secureRandom = Random.secure();

  @visibleForTesting
  String homePath;

  HiveImpl() : _manager = BackendManager() {
    _registerDefaultAdapters();
  }

  HiveImpl.debug(this._manager) {
    _registerDefaultAdapters();
  }

  void _registerDefaultAdapters() {
    registerAdapter(DateTimeAdapter(), internal: true);
    registerAdapter(BigIntAdapter(), internal: true);
    registerAdapter(DurationAdapter(), internal: true);
  }

  @override
  void init(String path) {
    homePath = path;

    _boxes.clear();
  }

  void _checkValidBoxName(String name) {
    assert(name.length <= 255 && name.isAscii,
        'Box names need to be ASCII Strings with a max length of 255.');
  }

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    HiveCipher encryptionCipher,
    KeyComparator keyComparator = const DefaultKeyComparator(),
    CompactionStrategy compactionStrategy = const DefaultCompactionStrategy(),
    bool crashRecovery = true,
    String path,
    Uint8List bytes,
  }) async {
    _checkValidBoxName(name);
    if (isBoxOpen(name)) {
      return box(name);
    }

    StorageBackend backend;
    if (bytes != null) {
      backend = StorageBackendMemory(bytes, encryptionCipher);
    } else {
      backend = await _manager.open(
          name, path ?? homePath, crashRecovery, encryptionCipher);
    }

    var newBox =
        BoxImpl<E>(this, name, keyComparator, compactionStrategy, backend);

    await newBox.initialize();
    _boxes[name] = newBox;

    return newBox;
  }

  @override
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    HiveCipher encryptionCipher,
    KeyComparator keyComparator = const DefaultKeyComparator(),
    CompactionStrategy compactionStrategy = const DefaultCompactionStrategy(),
    bool crashRecovery = true,
    String path,
  }) async {
    _checkValidBoxName(name);
    if (isBoxOpen(name)) {
      return lazyBox(name);
    }

    var backend = await _manager.open(
        name, path ?? homePath, crashRecovery, encryptionCipher);

    var newBox =
        LazyBoxImpl<E>(this, name, keyComparator, compactionStrategy, backend);

    await newBox.initialize();
    _boxes[name] = newBox;

    return newBox;
  }

  @override
  Future<IsolateBox<E>> openIsolateBox<E>(
    String name, {
    bool lazy = false,
    HiveCipher encryptionCipher,
    KeyComparator keyComparator = const DefaultKeyComparator(),
    CompactionStrategy compactionStrategy = const DefaultCompactionStrategy(),
    bool crashRecovery = true,
    String path,
  }) async {
    _checkValidBoxName(name);
    if (isBoxOpen(name)) {
      return isolateBox<E>(name);
    }

    var newBox = IsolateBoxImpl<E>(this, name, lazy, encryptionCipher,
        keyComparator, compactionStrategy, crashRecovery, path ?? homePath);

    await newBox.initialize();
    _boxes[name] = newBox;

    return newBox;
  }

  BoxBase getBoxWithoutCheckInternal(String name) {
    return _boxes[name];
  }

  void _checkBoxType<B>(dynamic box) {
    if (box == null) {
      throw HiveError('Box not found. Did you forget to call Hive.openBox()?');
    } else if (box is! B) {
      throw HiveError('You are trying to open a $B but the box is '
          'already open as ${box.runtimeType}.');
    }
  }

  @override
  Box<E> box<E>(String name) {
    var box = _boxes[name];
    _checkBoxType<Box<E>>(box);
    return box as Box<E>;
  }

  @override
  LazyBox<E> lazyBox<E>(String name) {
    var box = _boxes[name];
    _checkBoxType<LazyBox<E>>(box);
    return box as LazyBox<E>;
  }

  @override
  IsolateBox<E> isolateBox<E>(String name) {
    var box = _boxes[name];
    _checkBoxType<IsolateBox<E>>(box);
    return box as IsolateBox<E>;
  }

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name);
  }

  @override
  Future<void> close() {
    var closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  void unregisterBox(String name) {
    _boxes.remove(name);
  }

  @override
  Future<void> deleteBoxFromDisk(String name, {String path}) async {
    var box = _boxes[name];
    if (box != null) {
      await box.deleteFromDisk();
    } else {
      await _manager.deleteBox(name, path ?? homePath);
    }
  }

  @override
  Future<void> deleteFromDisk() {
    var deleteFutures = _boxes.values.toList().map((box) {
      return box.deleteFromDisk();
    });

    return Future.wait(deleteFutures);
  }

  @override
  List<int> generateSecureKey() {
    return _secureRandom.nextBytes(32);
  }
}
