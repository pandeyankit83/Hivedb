import 'package:hive/hive.dart';

class DefaultKeyComparator implements KeyComparator {
  const DefaultKeyComparator();

  @override
  int compareKeys(key1, key2) {
    if (key1 is int) {
      if (k1 > k2) {
        return 1;
      } else if (k1 < k2) {
        return -1;
      } else {
        return 0;
      }
    } else if (key2 is String) {
      return (key1 as String).compareTo(key2);
    } else {
      return 1;
    }
  }
}

const defaultKeyComparator = DefaultKeyComparator();
