import 'package:another_telephony/telephony.dart';

extension SmsMessageDateExt on SmsMessage {
  DateTime get receivedAt => date != null
      ? DateTime.fromMillisecondsSinceEpoch(date!)
      : DateTime.now();
}
