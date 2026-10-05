import 'sms_parse_result.dart';
import 'sms_wallet_candidate.dart';

/// Event dispatched when an SMS is successfully detected and processed by the engine.
final class SmsTransactionEvent {
  const SmsTransactionEvent({
    required this.sender,
    required this.rawBody,
    required this.receivedAt,
    required this.parseResult,
    this.matchedWallet,
  });

  final String sender;
  final String rawBody;
  final DateTime receivedAt;
  final SmsParseResult parseResult;
  final SmsWalletCandidate? matchedWallet;
}
