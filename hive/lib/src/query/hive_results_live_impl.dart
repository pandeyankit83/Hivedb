import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/query/delegating_results_list_live.dart';
import 'package:hive/src/query/hive_query_impl.dart';
import 'package:hive/src/query/unmodifiable_results_mixin.dart';

class HiveResultsLiveImpl<E extends HiveObject, Q extends HiveQueryBase<E>>
    extends DelegatingResultsListLive<E>
    with UnmodifiableResultsMixin<E>
    implements HiveResults<E, Q> {
  @override
  final HiveQueryImpl<E> query;

  final Stream<BoxEvent> _eventStream;

  StreamSubscription _subscription;

  HiveResultsLiveImpl(this.query, this._eventStream)
      : super(query.sortingComparator) {
    refresh();
  }

  @override
  Box get box => query.box;

  @override
  void refresh() {
    throw UnsupportedError(
        'Auto updating HiveResults must not be refreshed manually.');
  }

  void register() {
    _subscription = _eventStream.listen((event) {
      var value = event.value as E;
      if (event.deleted) {
        results.delete(value);
      } else {
        results.insert(value, null);
      }
    });
  }

  @override
  Stream<HiveResults<E, Q>> watch() {
    // TODO: implement watch
    return _eventStream.map(convert);
  }

  @override
  void close() {
    _subscription.cancel();
  }
}
