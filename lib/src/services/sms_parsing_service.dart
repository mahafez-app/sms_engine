import '../models/sms_parse_result.dart';
import '../registry/sms_parser_registry.dart';

/// Phase-1 of the SMS pipeline: extracts structured transaction signals
/// (amount, type, balance, counterparty) without committing to a specific wallet.
final class SmsParsingService {
  SmsParsingService._();

  /// Parses the SMS body into a [SmsParseResult] using registered regex parsers.
  ///
  /// Returns `null` if the sender is unrecognized or the body matches no pattern.
  static SmsParseResult? parseRaw({
    required String sender,
    required String message,
    required DateTime smsReceivedAt,
    bool useContentDate = false,
  }) {
    final parser = SmsParserRegistry.resolve(sender);
    if (parser == null) return null;
    return parser.parse(message, smsReceivedAt, useContentDate: useContentDate);
  }
}
