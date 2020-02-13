class IsolateRequest<T> {
  final int id;

  final int operation;

  final T data;

  const IsolateRequest(this.id, this.operation, this.data);
}

class IsolateResponse<T> {
  final int requestId;

  final T data;

  final dynamic error;

  const IsolateResponse(this.requestId, this.data) : error = null;

  const IsolateResponse.error(this.requestId, this.error) : data = null;
}
