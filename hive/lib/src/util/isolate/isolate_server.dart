import 'dart:isolate';

import 'package:hive/src/util/isolate/isolate_communication.dart';

typedef IsolateHandler = Future<dynamic> Function(int operation, dynamic data);

class IsolateServer {
  final SendPort sendPort;
  final IsolateHandler handler;

  IsolateServer(this.sendPort, this.handler);

  void serve() {
    var receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      _handleRequest(message as IsolateRequest);
    });
  }

  void _handleRequest(IsolateRequest request) {
    handler(request.operation, request.data).then((data) {
      var response = IsolateResponse(request.id, data);
      sendPort.send(response);
    }, onError: (e) {
      var response = IsolateResponse.error(request.id, e);
      sendPort.send(response);
    });
  }
}
