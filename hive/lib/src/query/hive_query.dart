part of hive;

abstract class HiveQuery<E extends HiveObject> extends HiveQueryBase<E> {
  HiveResults<E, HiveQuery<E>> find({bool autoUpdate = false});

  int count();
}
