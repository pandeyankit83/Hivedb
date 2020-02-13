@JS()
library indexed_db;

import 'dart:async';
import 'dart:html';
import 'package:js/js.dart';

@JS('IDBKeyRange')
class _IDBFactory {
  @JS()
  external _IDBRequest open(String name);

  @JS()
  external _IDBRequest deleteDatabase(String name);
}

@JS('IDBKeyRange')
class _IDBKeyRange {
  external static _IDBKeyRange lowerBound(int lower);

  external bool includes(dynamic key);
}

@JS('IDBRequest')
class _IDBRequest {
  @JS()
  external dynamic get result;

  @JS()
  external dynamic get error;

  @JS()
  external void addEventListener(
      String type, void Function(Event event) listener);
}

@JS('IDBDatabase')
class _IDBDatabase {
  @JS()
  external _IDBObjectStore createObjectStore(String name);

  @JS()
  external DomStringList get objectStoreNames;

  @JS()
  external _IDBTransaction transaction(String store, String mode);

  @JS()
  external void close();
}

@JS('IDBTransaction')
class _IDBTransaction {
  @JS()
  external _IDBObjectStore objectStore(String name);
}

@JS('IDBObjectStore')
class _IDBObjectStore {
  @JS()
  external _IDBRequest getAllKeys(Object query, [int count]);

  @JS()
  external _IDBRequest getAll(Object query, [int count]);

  @JS()
  external _IDBRequest get(Object key);

  @JS()
  external _IDBRequest put(Object value, Object key);

  @JS()
  external _IDBRequest delete(Object key);

  @JS()
  external _IDBRequest clear();
}

class Database {
  final String name;

  final _IDBDatabase _db;

  Database(this.name, this._db);

  @pragma('dart2js:tryInline')
  ObjectStore createObjectStore(String name) {
    return ObjectStore(_db.createObjectStore(name));
  }

  @pragma('dart2js:tryInline')
  bool hasObjectStore(String name) {
    return _db.objectStoreNames.contains(name);
  }

  @pragma('dart2js:tryInline')
  ObjectStore getStore(String name, bool write) {
    var mode = write ? 'readwrite' : 'readonly';
    var transaction = _db.transaction(name, mode);
    return ObjectStore(transaction.objectStore(name));
  }

  @pragma('dart2js:tryInline')
  void close() {
    _db.close();
  }

  @pragma('dart2js:tryInline')
  Future<void> delete() {
    return _requestToFuture(_indexedDb.deleteDatabase(name));
  }
}

class ObjectStore {
  final _IDBObjectStore _store;

  ObjectStore(this._store);

  @pragma('dart2js:tryInline')
  Future<List<dynamic>> getAllKeys([int count]) async {
    return await _requestToFuture(_store.getAllKeys(null, count)) as List;
  }

  @pragma('dart2js:tryInline')
  Future<List<dynamic>> getAllValues([int count]) async {
    return await _requestToFuture(_store.getAll(null, count)) as List;
  }

  @pragma('dart2js:tryInline')
  Future<dynamic> get(dynamic key) async {
    return _requestToFuture(_store.get(key));
  }

  @pragma('dart2js:tryInline')
  Future<void> put(dynamic key, dynamic value) {
    return _requestToFuture(_store.put(value, key));
  }

  @pragma('dart2js:tryInline')
  Future<void> delete(dynamic key) {
    return _requestToFuture(_store.delete(key));
  }

  @pragma('dart2js:tryInline')
  Future<void> clear() {
    return _requestToFuture(_store.clear());
  }
}

@JS('indexedDB')
external _IDBFactory get _indexedDb;

@pragma('dart2js:tryInline')
bool get idb2Support {
  if (_indexedDb == null) return false;
  try {
    var idb2 = _IDBKeyRange.lowerBound(0).includes(1);
    return idb2 == true;
  } catch (e) {
    return false;
  }
}

Future<dynamic> _requestToFuture(_IDBRequest request) {
  var completer = Completer.sync();
  var successCallback = allowInterop((Event e) {
    completer.complete(request.result);
  });
  var errorCallback = allowInterop((Event e) {
    completer.completeError(request.error);
  });
  request
    ..addEventListener('success', successCallback)
    ..addEventListener('error', errorCallback);
  return completer.future;
}

@pragma('dart2js:tryInline')
Future<Database> openIDB(
    String name, void Function(Database) onUpgradeNeeded) async {
  var request = _indexedDb.open(name);
  request.addEventListener('upgradeneeded', allowInterop((e) {
    var db = request.result as _IDBDatabase;
    onUpgradeNeeded(Database(name, db));
  }));

  var db = await _requestToFuture(request) as _IDBDatabase;
  return Database(name, db);
}
