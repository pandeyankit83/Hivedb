import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

abstract class BoxBaseImpl<E> implements BoxBase<E> {
  @override
  final String name;

  final HiveImpl hive;

  final Set<HiveObject> objectsToSave = {};

  var _open = true;

  BoxBaseImpl(this.hive, this.name);

  Type get valueType => E;

  @override
  bool get isOpen => _open;

  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError('Box has already been closed.');
    }
  }

  @protected
  void closeInternal() {
    _open = false;
    hive.unregisterBox(name);
  }

  @override
  Future<void> add(E value) async {
    return addAll([value]);
  }

  @override
  Future<void> put(dynamic key, E value) {
    return putAll({key: value});
  }

  @override
  Future<void> delete(dynamic key) {
    return putAll({}, keysToDelete: [key]);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) {
    return putAll({}, keysToDelete: keys);
  }

  Future<void> initialize();
}
