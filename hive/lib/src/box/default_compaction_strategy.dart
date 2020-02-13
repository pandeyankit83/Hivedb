import 'package:hive/hive.dart';

class DefaultCompactionStrategy implements CompactionStrategy {
  static const _deletedRatio = 0.15;
  static const _deletedThreshold = 60;

  const DefaultCompactionStrategy();

  @override
  bool shouldCompact(int entries, int deletedEntries) {
    return deletedEntries > _deletedThreshold &&
        deletedEntries / entries > _deletedRatio;
  }
}
