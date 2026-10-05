import 'package:mahafez_core/mahafez_core.dart';
import '../models/sms_match_result.dart';

class SmsPatternMatcher {
  SmsPatternMatcher._();

  /// Tries all standard receive/send patterns in order.
  /// Returns the first match, or null if nothing matches.
  static SmsMatchResult? match(
    String message, {
    List<RegExp> receivePatterns = const [],
    List<RegExp> sendPatterns = const [],
  }) {
    for (final pattern in receivePatterns) {
      final m = pattern.firstMatch(message);
      if (m != null) {
        final amount = _parseAmount(m.group(1)!);
        if (amount == null) continue;
        return SmsMatchResult(
          amount: amount,
          type: TransactionType.receive,
          counterpartyNumber: m.groupCount >= 2
              ? _normalizeNumber(m.group(2))
              : null,
        );
      }
    }

    for (final pattern in sendPatterns) {
      final m = pattern.firstMatch(message);
      if (m != null) {
        final amount = _parseAmount(m.group(1)!);
        if (amount == null) continue;
        return SmsMatchResult(
          amount: amount,
          type: TransactionType.send,
          counterpartyNumber: m.groupCount >= 2
              ? _normalizeNumber(m.group(2))
              : null,
        );
      }
    }

    return null;
  }

  static double? _parseAmount(String raw) =>
      double.tryParse(raw.replaceAll(',', '').trim());

  /// Normalises Egyptian mobile numbers to local 01xxxxxxxxx (11-digit) format.
  static String? _normalizeNumber(String? raw) {
    return EgyptianPhoneNumber.tryNormalizeMobile(raw);
  }
}
