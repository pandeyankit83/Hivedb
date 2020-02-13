part of hive;

extension HiveListExtension<E extends HiveObject> on Iterable<E> {
  /// The keys of all the objects in this collection.
  Iterable<dynamic> get keys sync* {
    for (var value in this) {
      yield value.key;
    }
  }

  /// Delete all objects in this collection from Hive.
  Future<void> deleteAllFromHive() {
    if (isEmpty) return Future.value();

    BoxBase box;
    var keysIterable = map((it) {
      if (box == null) {
        box = it.box;
      } else if (it.box != box) {
        throw HiveError('This method only works on lists which contain '
            'objects stored in the same box.');
      }
      return it.key;
    });

    return box.deleteAll(keysIterable);
  }

  /// Delete the first object in this collection from Hive.
  Future<void> deleteFirstFromHive() {
    return first.delete();
  }

  /// Delete the last object in this collection from Hive.
  Future<void> deleteLastFromHive() {
    return last.delete();
  }

  /// Delete the object at [index] from Hive.
  Future<void> deleteFromHive(int index) {
    return elementAt(index).delete();
  }

  /// Converts this collection to a Map.
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var item in this) {
      map[item.key] = item;
    }
    return map;
  }
}
