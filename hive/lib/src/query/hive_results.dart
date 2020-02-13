part of hive;

abstract class HiveResults<E extends HiveObject, Q extends HiveQueryBase<E>>
    implements List<E> {
  Q get query;

  Box get box;

  void refresh();

  Stream<HiveResults<E, Q>> watch();

  void close();
}
