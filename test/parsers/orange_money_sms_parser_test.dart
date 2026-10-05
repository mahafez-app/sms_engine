import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:mahafez_sms_engine/mahafez_sms_engine.dart';

void main() {
  const parser = OrangeMoneySmsParser();
  final now = DateTime(2026, 4, 20, 12);

  group('OrangeMoneySmsParser Tests', () {
    test('parses Arabic receive SMS', () {
      final result = parser.parse(
        'تم استلام مبلغ 1000 جنيه من رقم 01222222222 رصيدك الحالي 3000 جنيه كود العملية 123456',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.orangeMoney);
      expect(result.type, TransactionType.receive);
      expect(result.amount, 1000);
      expect(result.counterpartyNumber, '01222222222');
      expect(result.referenceNumber, '123456');
    });

    test('parses Arabic send SMS', () {
      final result = parser.parse(
        'تم تحويل 250 جنيه لرقم 01233333333 رصيدك الحالي 2750 جنيه رقم العملية 987654',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.orangeMoney);
      expect(result.type, TransactionType.send);
      expect(result.amount, 250);
      expect(result.counterpartyNumber, '01233333333');
      expect(result.referenceNumber, '987654');
    });
  });
}
