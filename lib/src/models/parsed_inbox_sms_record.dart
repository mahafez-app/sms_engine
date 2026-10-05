import 'sms_parse_result.dart';

typedef ParsedInboxSmsRecord = ({
  DateTime createdAt,
  String body,
  SmsParseResult parseResult,
});
