import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:mahafez_sms_engine/mahafez_sms_engine.dart';

void main() {
  final wallets = [
    const SimpleSmsWalletCandidate(
      id: 'wallet-a',
      phoneNumber: '01011111111',
      currentBalance: 14212.66,
    ),
    const SimpleSmsWalletCandidate(
      id: 'wallet-b',
      phoneNumber: '01022222222',
      currentBalance: 4000,
    ),
  ];

  group('SmsWalletMatcher Tests', () {
    test('matches wallet by balance delta when unique', () {
      final result = SmsWalletMatcher.resolve(
        wallets: wallets,
        input: const SmsWalletMatchInput(
          amount: 6750,
          transactionType: TransactionType.send,
          parsedBalance: 7462.66,
          counterpartyNumber: '01020565524',
          mentionedPhoneNumbers: ['01020565524'],
        ),
      );

      expect(result, isA<SmsWalletMatchedResult<SimpleSmsWalletCandidate>>());
      expect(
        (result as SmsWalletMatchedResult<SimpleSmsWalletCandidate>).wallet.id,
        'wallet-a',
      );
    });

    test('returns no candidate instead of unsafe fallback', () {
      final result = SmsWalletMatcher.resolve(
        wallets: wallets,
        input: const SmsWalletMatchInput(
          amount: 100,
          transactionType: TransactionType.send,
          parsedBalance: 50,
        ),
      );

      expect(result, isA<SmsWalletNoCandidate<SimpleSmsWalletCandidate>>());
    });

    test('matches wallet by explicit phone mention', () {
      final result = SmsWalletMatcher.resolve(
        wallets: wallets,
        input: const SmsWalletMatchInput(
          amount: 500,
          transactionType: TransactionType.receive,
          counterpartyNumber: '01099999999',
          mentionedPhoneNumbers: ['01099999999', '01022222222'],
        ),
      );

      expect(result, isA<SmsWalletMatchedResult<SimpleSmsWalletCandidate>>());
      expect(
        (result as SmsWalletMatchedResult<SimpleSmsWalletCandidate>).wallet.id,
        'wallet-b',
      );
    });
  });
}
