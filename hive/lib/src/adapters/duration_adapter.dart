import 'package:hive/hive.dart';

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final typeId = 17;

  @override
  Duration read(BinaryReader reader) {
    var micros = reader.readInt();
    return Duration(microseconds: micros);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
