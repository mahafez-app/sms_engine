import 'package:mahafez_core/mahafez_core.dart';
import '../parsers/etisalat_cash_sms_parser.dart';
import '../parsers/insta_pay_sms_parser.dart';
import '../parsers/orange_money_sms_parser.dart';
import '../parsers/sms_parser.dart';
import '../parsers/vodafone_cash_sms_parser.dart';
import '../parsers/we_pay_sms_parser.dart';

/// Maps incoming SMS sender IDs to their [SmsParser] implementations.
///
/// The built-in parser list is treated as immutable at compile time.
/// Use [register] to extend it at runtime (e.g. from remote config).
final class SmsParserRegistry {
  SmsParserRegistry._();

  static const List<SmsParser> _builtIn = [
    VodafoneCashSmsParser(),
    OrangeMoneySmsParser(),
    EtisalatCashSmsParser(),
    WePaySmsParser(),
    InstaPaySmsParser(),
  ];

  /// Extra parsers added at runtime via [register].
  static final List<SmsParser> _extras = [];

  /// Returns the parser for [sender], or `null` if the sender is unknown.
  static SmsParser? resolve(String sender) {
    final normalized = _normalizeSender(sender);
    for (final parser in [..._builtIn, ..._extras]) {
      for (final id in parser.senderIds) {
        if (normalized.contains(_normalizeSender(id))) return parser;
      }
    }
    return null;
  }

  /// Returns the parser for [provider], or `null` if the provider has no parser.
  static SmsParser? resolveByProvider(WalletProvider provider) {
    for (final parser in [..._builtIn, ..._extras]) {
      if (parser.provider == provider) return parser;
    }
    return null;
  }

  /// Registers an additional parser at runtime.
  ///
  /// Idempotent: registering the same parser type twice has no effect.
  static void register(SmsParser parser) {
    final alreadyRegistered = _extras.any(
      (p) => p.runtimeType == parser.runtimeType,
    );
    if (!alreadyRegistered) _extras.add(parser);
  }

  static String _normalizeSender(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
}
