import 'package:mahafez_core/mahafez_core.dart';

class SmsMatchResult {
  const SmsMatchResult({
    required this.amount,
    required this.type,
    this.counterpartyNumber,
    this.balance,
  });

  final double amount;
  final TransactionType type;
  final String? counterpartyNumber;
  final double? balance;
}
