import 'dart:io';
import 'dart:isolate';

import 'package:hive/hive.dart';
import 'package:hive/src/util/isolate/isolate_server.dart';

void isolateEntryPoint(SendPort sendPort) {
  var runner = IsolateRunner();
  var server = IsolateServer(sendPort, runner.handleRequest);
  server.serve();
}

typedef IsolateOperation = Future<dynamic> Function(
    LocalBoxBase box, dynamic data);

class IsolateRunner {
  static const List<IsolateOperation> operations = [
    //
    getLength, getKeys, keyAt, containsKey, getValues,
    valuesBetween, watch, get, getAt, toMap, putAt, putAll, addAll,
    deleteAt, compact, clear, close, deleteFromDisk
  ];

  static Map<IsolateOperation, int> get operationsMap {
    var map = <IsolateOperation, int>{};
    for (var i = 0; i < operations.length; i++) {
      map[operations[i]] = i;
    }
    return map;
  }

  LocalBoxBase _box;

  Future<dynamic> handleRequest(int operationId, dynamic data) async {
    if (operationId == -1) {
      assert(_box == null);
      _box = await initialize(data);
    } else {
      var operation = operations[operationId];
      return operation(_box, data);
    }
  }

  Future<LocalBoxBase> initialize(dynamic data) {
    var params = data as RemoteBoxParameters;
    /*if (params.lazy) {
      box = await Hive.openLazyBox(
        params.name,
        encryptionCipher: params.encryptionCipher,
        keyComparator: params.keyComparator,
        compactionStrategy: params.compactionStrategy,
        crashRecovery: params.crashRecovery,
        path: params.path,
      );
    } else {
      box = await Hive.openBox(
        params.name,
        encryptionCipher: params.encryptionCipher,
        keyComparator: params.keyComparator,
        compactionStrategy: params.compactionStrategy,
        crashRecovery: params.crashRecovery,
        path: params.path,
      );
    }*/
    return Hive.openBox('name', path: Directory.current.path);
  }

  static Future<dynamic> getLength(LocalBoxBase box, dynamic _) {
    return Future.value(box.length);
  }

  static Future<dynamic> getKeys(LocalBoxBase box, dynamic _) {
    return Future.value(box.keys);
  }

  static Future<dynamic> keyAt(LocalBoxBase box, dynamic index) {
    return Future.value(box.keyAt(index as int));
  }

  static Future<dynamic> containsKey(LocalBoxBase box, dynamic key) {
    return Future.value(box.containsKey(key));
  }

  static Future<dynamic> getValues(LocalBoxBase box, dynamic _) {
    return Future.value((box as Box).values.toList());
  }

  static Future<dynamic> valuesBetween(LocalBoxBase box, dynamic data) {
    var values = (box as Box).valuesBetween(startKey: data[0], endKey: data[1]);
    return Future.value(values);
  }

  static Future<dynamic> watch(LocalBoxBase box, dynamic data) {
    var sendPort = data[0] as SendPort;
    var key = data[1];
    var subscription = box.watch(key: key).listen((event) {
      sendPort.send(event);
    });

    var receivePort = ReceivePort();
    receivePort.first.then((value) {
      subscription.cancel();
      receivePort.close();
    });

    return Future.value(receivePort.sendPort);
  }

  static Future<dynamic> get(LocalBoxBase box, dynamic data) {
    if (box.isLazy) {
      return (box as LazyBox).get(data[0], defaultValue: data[1]);
    } else {
      var value = (box as Box).get(data[0], defaultValue: data[1]);
      return Future.value(value);
    }
  }

  static Future<dynamic> getAt(LocalBoxBase box, dynamic index) {
    if (box.isLazy) {
      return (box as LazyBox).getAt(index as int);
    } else {
      var value = (box as Box).getAt(index as int);
      return Future.value(value);
    }
  }

  static Future<dynamic> toMap(LocalBoxBase box, dynamic _) {
    return Future.value((box as Box).toMap());
  }

  static Future<dynamic> putAt(LocalBoxBase box, dynamic data) {
    return box.putAt(data[0] as int, data[1]);
  }

  static Future<dynamic> putAll(LocalBoxBase box, dynamic data) {
    return box.putAll(data[0] as Map, keysToDelete: data[1] as List);
  }

  static Future<dynamic> addAll(LocalBoxBase box, dynamic values) {
    return box.addAll(values as List);
  }

  static Future<dynamic> deleteAt(LocalBoxBase box, dynamic index) {
    return box.deleteAt(index as int);
  }

  static Future<dynamic> compact(LocalBoxBase box, dynamic _) {
    return box.compact();
  }

  static Future<dynamic> clear(LocalBoxBase box, dynamic _) {
    return box.clear();
  }

  static Future<dynamic> close(LocalBoxBase box, dynamic _) {
    return box.close();
  }

  static Future<dynamic> deleteFromDisk(LocalBoxBase box, dynamic _) {
    return box.deleteFromDisk();
  }
}

class RemoteBoxParameters {
  final String name;
  final bool lazy;
  final HiveCipher encryptionCipher;
  final KeyComparator keyComparator;
  final CompactionStrategy compactionStrategy;
  final bool crashRecovery;
  final String path;
  final Map<int, TypeAdapter> adapters;

  const RemoteBoxParameters({
    this.name,
    this.lazy,
    this.encryptionCipher,
    this.keyComparator,
    this.compactionStrategy,
    this.crashRecovery,
    this.path,
    this.adapters,
  });
}
