import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

abstract class LocalBoxBaseImpl<E> extends BoxBaseImpl<E>
    implements LocalBoxBase<E> {
  @override
  final bool isIsolate = false;

  final CompactionStrategy _compactionStrategy;

  @protected
  final StorageBackend backend;

  @protected
  @visibleForTesting
  Keystore<E> keystore;

  LocalBoxBaseImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    this._compactionStrategy,
    this.backend,
  ) : super(hive, name) {
    keystore = Keystore(this, ChangeNotifier(), keyComparator);
  }

  @override
  String get path => backend.path;

  @override
  Iterable<dynamic> get keys {
    checkOpen();
    return keystore.getKeys();
  }

  @override
  int get length {
    checkOpen();
    return keystore.length;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    checkOpen();
    return keystore.watch(key: key);
  }

  @override
  dynamic keyAt(int index) {
    checkOpen();
    return keystore.getAt(index).key;
  }

  @override
  Future<void> initialize() {
    return backend.initialize(hive, keystore, isLazy);
  }

  @override
  bool containsKey(dynamic key) {
    checkOpen();
    return keystore.containsKey(key);
  }

  @override
  int autoIncrement() {
    checkOpen();
    return keystore.autoIncrement();
  }

  @override
  Future<void> addAll(Iterable<E> values) {
    return putAll({
      for (var value in values) keystore.autoIncrement(): value,
    });
  }

  @override
  Future<void> putAt(int index, E value) {
    return putAll({keystore.getAt(index).key: value});
  }

  @override
  Future<void> deleteAt(int index) {
    return deleteAll([keystore.getAt(index).key]);
  }

  @override
  Future<int> clear() async {
    checkOpen();

    await backend.clear();
    return keystore.clear();
  }

  @override
  Future<void> compact() async {
    checkOpen();

    if (!backend.supportsCompaction) return;
    if (keystore.deletedEntries == 0) return;

    await backend.compact(keystore.frames);
    keystore.resetDeletedEntries();
  }

  @protected
  Future<void> performCompactionIfNeeded() {
    if (_compactionStrategy.shouldCompact(
        keystore.length, keystore.deletedEntries)) {
      return compact();
    }

    return Future.value();
  }

  @override
  Future<void> close() async {
    if (!isOpen) return;

    closeInternal();
    await keystore.close();
    await backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    if (isOpen) {
      closeInternal();
      await keystore.close();
    }

    await backend.deleteFromDisk();
  }
}
