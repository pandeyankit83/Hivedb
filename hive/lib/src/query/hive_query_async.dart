part of hive;

abstract class AsyncHiveQuery<E extends HiveObject> extends HiveQueryBase<E> {
  Future<HiveResults<E, AsyncHiveQuery<E>>> find({bool autoUpdate = false});

  Future<int> count();
}

abstract class QueryBuilder<E extends HiveObject> {
  HiveQuery<E> build(HiveQuery<E> query);
}
