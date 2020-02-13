import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/local/local_box_base_impl.dart';
import 'package:hive/src/hive_impl.dart';

class BoxImpl<E> extends LocalBoxBaseImpl<E> implements Box<E> {
  BoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
  ) : super(hive, name, keyComparator, compactionStrategy, backend);

  @override
  final bool isLazy = false;

  @override
  Iterable<E> get values {
    checkOpen();

    return keystore.getValues();
  }

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) {
    checkOpen();

    return keystore.getValuesBetween(startKey, endKey);
  }

  @override
  E get(dynamic key, {E defaultValue}) {
    checkOpen();

    var frame = keystore.get(key);
    if (frame != null) {
      return frame.value as E;
    } else {
      return defaultValue;
    }
  }

  @override
  E getAt(int index) {
    checkOpen();

    return keystore.getAt(index).value as E;
  }

  @override
  Future<void> putAll(Map<dynamic, E> entries,
      {Iterable<dynamic> keysToDelete}) async {
    checkOpen();
    var frames = <Frame>[];

    if (keysToDelete != null) {
      for (var key in keysToDelete) {
        frames.add(Frame.deleted(key));
      }
    }

    for (var key in entries.keys) {
      frames.add(Frame(key, entries[key]));
    }

    if (!keystore.beginTransaction(frames)) return;

    try {
      await backend.writeFrames(frames);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var frame in keystore.frames) {
      map[frame.key] = frame.value as E;
    }
    return map;
  }
}
