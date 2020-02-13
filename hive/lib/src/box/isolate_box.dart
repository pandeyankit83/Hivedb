import 'package:hive/hive.dart';

abstract class IsolateBox<E> implements BoxBase<E> {
  /// All the keys in the box.
  ///
  /// The keys are sorted alphabetically in ascending order.
  Future<Iterable<dynamic>> get keys;

  /// The number of entries in the box.
  Future<int> get length;

  /// Returns `true` if there are no entries in this box.
  Future<bool> get isEmpty;

  /// Returns true if there is at least one entries in this box.
  Future<bool> get isNotEmpty;

  /// Get the n-th key in the box.
  Future<dynamic> keyAt(int index);

  /// Checks whether the box contains the [key].
  Future<bool> containsKey(dynamic key);

  /// All the values in the box.
  ///
  /// The values are in the same order as their keys.
  Future<Iterable<E>> get values;

  /// Returns an iterable which contains all values starting with the value
  /// associated with [startKey] (inclusive) to the value associated with
  /// [endKey] (inclusive).
  ///
  /// If [startKey] does not exist, an empty iterable is returned. If [endKey]
  /// does not exist or is before [startKey], it is ignored.
  ///
  /// The values are in the same order as their keys.
  Future<Iterable<E>> valuesBetween({dynamic startKey, dynamic endKey});

  /// Returns the value associated with the given [key]. If the key does not
  /// exist, `null` is returned.
  ///
  /// If [defaultValue] is specified, it is returned in case the key does not
  /// exist.
  Future<E> get(dynamic key, {E defaultValue});

  /// Returns the value associated with the n-th key.
  Future<E> getAt(int index);

  /// Returns a map which contains all key - value pairs of the box.
  Future<Map<dynamic, E>> toMap();
}
