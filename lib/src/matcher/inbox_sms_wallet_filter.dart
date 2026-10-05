import 'package:mahafez_core/mahafez_core.dart';
import '../models/sms_parse_result.dart';
import '../registry/sms_parser_registry.dart';

final class InboxSmsWalletFilter {
  const InboxSmsWalletFilter._();

  static DateTime resolveMessageDate(int? timestampMs) {
    if (timestampMs == null) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(timestampMs);
  }

  static bool shouldUseMessageForWallet({
    required String sender,
    required String body,
    required DateTime smsReceivedAt,
    required String targetPhoneNumber,
    required List<String> sameProviderWalletPhoneNumbers,
  }) {
    final parser = SmsParserRegistry.resolve(sender);
    if (parser == null) return false;
    final parseResult = parser.parse(body, smsReceivedAt);
    if (parseResult == null) return false;

    return shouldUseParsedSmsForWallet(
      parseResult: parseResult,
      targetPhoneNumber: targetPhoneNumber,
      sameProviderWalletPhoneNumbers: sameProviderWalletPhoneNumbers,
    );
  }

  static bool shouldUseParsedSmsForWallet({
    required SmsParseResult parseResult,
    required String targetPhoneNumber,
    required List<String> sameProviderWalletPhoneNumbers,
  }) {
    final normalizedTargetPhoneNumber = EgyptianPhoneNumber.tryNormalizeMobile(
      targetPhoneNumber,
    );
    if (normalizedTargetPhoneNumber == null) return false;

    final providerWalletPhoneNumbers =
        sameProviderWalletPhoneNumbers
            .map(EgyptianPhoneNumber.tryNormalizeMobile)
            .whereType<String>()
            .toSet()
          ..add(normalizedTargetPhoneNumber);

    final targetMentioned = parseResult.mentionedPhoneNumbers.contains(
      normalizedTargetPhoneNumber,
    );
    final explicitWalletPhone = _resolveExplicitWalletPhone(parseResult);
    if (explicitWalletPhone != null) {
      if (explicitWalletPhone == normalizedTargetPhoneNumber) {
        return true;
      }

      if (!targetMentioned) {
        return false;
      }
    }

    final mentionedWalletPhoneNumbers = parseResult.mentionedPhoneNumbers
        .where(providerWalletPhoneNumbers.contains)
        .toSet();

    return mentionedWalletPhoneNumbers.length == 1 &&
        mentionedWalletPhoneNumbers.first == normalizedTargetPhoneNumber;
  }

  static String? _resolveExplicitWalletPhone(SmsParseResult parseResult) {
    final counterparty = EgyptianPhoneNumber.tryNormalizeMobile(
      parseResult.counterpartyNumber,
    );
    final nonCounterpartyMentions = parseResult.mentionedPhoneNumbers
        .where((number) => number != counterparty)
        .toSet();

    if (nonCounterpartyMentions.length != 1) {
      return null;
    }

    return nonCounterpartyMentions.first;
  }
}
