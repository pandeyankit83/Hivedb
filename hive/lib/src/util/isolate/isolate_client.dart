import 'dart:async';
import 'dart:isolate';

import 'package:hive/src/util/isolate/isolate_communication.dart';

typedef IsolateEntry = void Function(SendPort sendPort);

class IsolateClient {
  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final Map<int, Completer> _pendingRequest = {};

  var _requestCounter = 0;

  IsolateClient(this._isolate, this._sendPort, this._receivePort);

  static Future<IsolateClient> create(IsolateEntry entryPoint) async {
    var receivePort = ReceivePort();
    var isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);

    var stream = receivePort.asBroadcastStream();
    var sendPort = await stream.first as SendPort;
    var client = IsolateClient(isolate, sendPort, receivePort);

    stream.listen((message) {
      if (message is IsolateResponse) {
        var pendingRequest = client._pendingRequest[message.requestId];
        if (message.error != null) {
          pendingRequest.completeError(message.error);
        } else {
          pendingRequest.complete(message.data);
        }
      } else {
        throw StateError('Isolate sent illegal message');
      }
    });

    return client;
  }

  Future<dynamic> sendRequest(int operation, dynamic data) {
    var requestId = _requestCounter++;
    var completer = Completer();
    _pendingRequest[requestId] = completer;

    var request = IsolateRequest(requestId, operation, data);
    _sendPort.send(request);

    return completer.future;
  }

  Future<void> shutdown() async {
    var pendingFutures = _pendingRequest.values.map((r) => r.future);
    await Future.wait(pendingFutures);
    _isolate.kill();
    _receivePort.close();
  }
}
