/// Abstract contract representing a candidate wallet for SMS matching.
///
/// Decouples the SMS engine from product-level Wallet entities.
abstract interface class SmsWalletCandidate {
  String get id;
  String get phoneNumber;
  double get currentBalance;
}

/// Concrete lightweight candidate implementation.
final class SimpleSmsWalletCandidate implements SmsWalletCandidate {
  const SimpleSmsWalletCandidate({
    required this.id,
    required this.phoneNumber,
    required this.currentBalance,
  });

  @override
  final String id;

  @override
  final String phoneNumber;

  @override
  final double currentBalance;
}
