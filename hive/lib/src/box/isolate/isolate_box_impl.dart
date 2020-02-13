import 'dart:async';
import 'dart:isolate';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/isolate/isolate_runner.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/util/isolate/isolate_client.dart';

class IsolateBoxImpl<E> extends BoxBaseImpl<E> implements IsolateBox<E> {
  final Map<IsolateOperation, int> _operationsMap = IsolateRunner.operationsMap;
  IsolateClient _client;

  @override
  final bool isLazy;

  @override
  final bool isIsolate = true;

  @override
  final String path;

  RemoteBoxParameters params;

  IsolateBoxImpl(
    HiveImpl hive,
    String name,
    this.isLazy,
    HiveCipher encryptionCipher,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    bool crashRecovery,
    this.path,
  ) : super(hive, name) {
    params = RemoteBoxParameters(
      name: name,
      lazy: isLazy,
      encryptionCipher: encryptionCipher,
      keyComparator: keyComparator,
      compactionStrategy: compactionStrategy,
      crashRecovery: crashRecovery,
    );
  }

  Future<dynamic> _sendRequest(IsolateOperation operation, [dynamic data]) {
    checkOpen();

    var operationId = _operationsMap[operation];
    return _client.sendRequest(operationId, data);
  }

  @override
  Future<void> initialize() async {
    _client = await IsolateClient.create(isolateEntryPoint);

    await _client.sendRequest(-1, params);
  }

  @override
  Future<int> get length async {
    var length = await _sendRequest(IsolateRunner.getLength);
    return length as int;
  }

  @override
  Future<bool> get isEmpty async {
    return await length == 0;
  }

  @override
  Future<bool> get isNotEmpty async {
    return await length != 0;
  }

  @override
  Future<Iterable> get keys async {
    var keys = await _sendRequest(IsolateRunner.getKeys);
    return keys as Iterable;
  }

  @override
  Future<dynamic> keyAt(int index) {
    return _sendRequest(IsolateRunner.keyAt, index);
  }

  @override
  Future<bool> containsKey(key) async {
    var containsKey = await _sendRequest(IsolateRunner.containsKey, key);
    return containsKey as bool;
  }

  @override
  Future<Iterable<E>> get values async {
    _checkNonLazyForMultiValueAccess();
    var values = await _sendRequest(IsolateRunner.getValues);
    return (values as Iterable).cast();
  }

  @override
  Future<Iterable<E>> valuesBetween({startKey, endKey}) async {
    _checkNonLazyForMultiValueAccess();
    var params = [startKey, endKey];
    var values = await _sendRequest(IsolateRunner.valuesBetween, params);
    return (values as Iterable).cast();
  }

  @override
  Stream<BoxEvent> watch({key}) {
    ReceivePort receivePort;
    Future<dynamic> sendPort;

    StreamController<BoxEvent> controller;
    controller = StreamController<BoxEvent>.broadcast(onListen: () {
      receivePort = ReceivePort();
      controller.addStream(receivePort.cast());
      var params = [receivePort.sendPort, key];
      sendPort = _sendRequest(IsolateRunner.watch, params);
    }, onCancel: () async {
      receivePort.close();
      (await sendPort).send(null);
    });

    return controller.stream;
  }

  @override
  Future<E> get(key, {E defaultValue}) async {
    var value = await _sendRequest(IsolateRunner.get, [key, defaultValue]);
    return value as E;
  }

  @override
  Future<E> getAt(int index) async {
    var value = await _sendRequest(IsolateRunner.getAt, index);
    return value as E;
  }

  @override
  Future<Map<dynamic, E>> toMap() async {
    _checkNonLazyForMultiValueAccess();
    var map = await _sendRequest(IsolateRunner.toMap);
    return (map as Map).cast();
  }

  @override
  Future<void> putAt(int index, E value) {
    return _sendRequest(IsolateRunner.putAt, [index, value]);
  }

  @override
  Future<void> putAll(Map<dynamic, E> entries,
      {Iterable<dynamic> keysToDelete}) {
    return _sendRequest(IsolateRunner.putAll, [entries, keysToDelete]);
  }

  @override
  Future<void> addAll(Iterable<E> values) {
    return _sendRequest(IsolateRunner.addAll, values);
  }

  @override
  Future<void> deleteAt(int index) {
    return _sendRequest(IsolateRunner.deleteAt, index);
  }

  @override
  Future<void> compact() {
    return _sendRequest(IsolateRunner.compact);
  }

  @override
  Future<int> clear() async {
    var count = await _sendRequest(IsolateRunner.clear);
    return count as int;
  }

  @override
  Future<void> close() async {
    await _sendRequest(IsolateRunner.close);
    await _client.shutdown();
    closeInternal();
  }

  @override
  Future<void> deleteFromDisk() async {
    await _sendRequest(IsolateRunner.deleteFromDisk);
    await _client.shutdown();
    closeInternal();
  }

  void _checkNonLazyForMultiValueAccess() {
    if (isLazy) {
      throw HiveError(
          'Only non-lazy boxes allow access to multiple values at once.');
    }
  }
}
