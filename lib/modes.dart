import 'dart:typed_data';

class EventLog {
  String eventUid;
  String deviceUid;
  int deviceSeq;
  String streamName;
  int streamSeq;
  String data; // could use Uint8List here?

  EventLog({
    required this.eventUid,
    required this.deviceUid,
    required this.deviceSeq,
    required this.streamName,
    required this.streamSeq,
    required this.data,
  });

  EventLog.fromRow(Map<String, dynamic> map)
    : eventUid = map['event_uid'],
      deviceUid = map['device_uid'],
      deviceSeq = map['device_seq'],
      streamName = map['stream_name'],
      streamSeq = map['stream_seq'],
      data = map['data'];
}
