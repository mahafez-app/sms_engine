import 'package:mahafez_core/mahafez_core.dart';

class SmsParseResult {
  const SmsParseResult({
    required this.amount,
    required this.type,
    required this.createdAt,
    required this.provider,
    this.counterpartyNumber,
    this.referenceNumber,
    this.balance,
    this.mentionedPhoneNumbers = const <String>[],
  });

  final double amount;
  final TransactionType type;
  final DateTime createdAt;
  final WalletProvider provider;
  final String? counterpartyNumber;
  final String? referenceNumber;
  final double? balance;
  final List<String> mentionedPhoneNumbers;
}
