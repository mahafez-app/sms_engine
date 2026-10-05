import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:mahafez_sms_engine/mahafez_sms_engine.dart';

void main() {
  test(
    'keeps only explicit target records when same-provider wallets coexist',
    () {
      final records = <ParsedInboxSmsRecord>[
        (
          createdAt: DateTime(2026, 4, 18, 10),
          body: 'ambiguous',
          parseResult: SmsParseResult(
            amount: 200,
            type: TransactionType.receive,
            createdAt: DateTime(2026, 4, 18, 10),
            provider: WalletProvider.vodafoneCash,
            counterpartyNumber: '01099999999',
            balance: 1200,
            mentionedPhoneNumbers: const ['01099999999'],
          ),
        ),
        (
          createdAt: DateTime(2026, 4, 18, 11),
          body: 'target',
          parseResult: SmsParseResult(
            amount: 500,
            type: TransactionType.receive,
            createdAt: DateTime(2026, 4, 18, 11),
            provider: WalletProvider.vodafoneCash,
            counterpartyNumber: '01099999999',
            balance: 1700,
            mentionedPhoneNumbers: const ['01011111111', '01099999999'],
          ),
        ),
        (
          createdAt: DateTime(2026, 4, 18, 12),
          body: 'other',
          parseResult: SmsParseResult(
            amount: 300,
            type: TransactionType.send,
            createdAt: DateTime(2026, 4, 18, 12),
            provider: WalletProvider.vodafoneCash,
            counterpartyNumber: '01099999999',
            balance: 900,
            mentionedPhoneNumbers: const ['01022222222', '01099999999'],
          ),
        ),
      ];

      final result = InboxSmsHistoryMatcher.resolveWalletHistory(
        records: records,
        targetPhoneNumber: '01011111111',
        sameProviderPhoneNumbers: const ['01011111111', '01022222222'],
      );

      expect(result, hasLength(1));
      expect(result.single.body, 'target');
    },
  );
}
