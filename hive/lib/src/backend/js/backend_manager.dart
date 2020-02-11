import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/indexed_db.dart';
import 'package:hive/src/backend/js/storage_backend_js.dart';
import 'package:hive/src/backend/storage_backend.dart';

class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String path, bool crashRecovery, HiveCipher cipher) async {
    if (!idb2Support) {
      throw HiveError('Your current browser does not support IndexedDB 2.0. '
          'Hive requires IndexedDB support to store its data.');
    }
    var db = await openIDB(name, (db) {
      if (!db.hasObjectStore('box')) {
        db.createObjectStore('box');
      }
    });

    return StorageBackendJs(db, cipher);
  }

  @override
  Future<void> deleteBox(String name, String path) {
    return Database(name, null).delete();
  }
}
