part of hive;

abstract class HiveQueryBase<E extends HiveObject> {
  const HiveQueryBase();

  HiveQueryBase<E> filter<T extends E>(Predicate<T> predicate);

  HiveQueryBase<E> exclude<T extends E>(Predicate<T> predicate);

  HiveQueryBase<E> offset(int offset);

  HiveQueryBase<E> limit(int limit);

  HiveQueryBase<E> order([Sort sort = Sort.asc]);

  HiveQueryBase<E> orderBy(
    ValueComparable<E> value, [
    Sort sort = Sort.asc,
    ValueComparable<E> value2,
    Sort sort2 = Sort.asc,
    ValueComparable<E> value3,
    Sort sort3 = Sort.asc,
  ]);

  HiveQueryBase<E> orderWith(Comparator<E> comparator, [Sort sort = Sort.asc]);
}

enum Sort { asc, desc }

typedef Predicate<E> = bool Function(E item);

typedef ValueComparable<E> = Comparable Function(E item);
