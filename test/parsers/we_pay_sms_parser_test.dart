import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:mahafez_sms_engine/mahafez_sms_engine.dart';

void main() {
  const parser = WePaySmsParser();
  final now = DateTime(2026, 4, 20, 12);

  group('WePaySmsParser Tests', () {
    test('parses Arabic receive SMS', () {
      final result = parser.parse(
        'تم استلام مبلغ 400 جنيه من رقم 01555555555 رصيدك الحالي 800 جنيه رقم العملية 112233',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.wePay);
      expect(result.type, TransactionType.receive);
      expect(result.amount, 400);
      expect(result.counterpartyNumber, '01555555555');
      expect(result.referenceNumber, '112233');
    });

    test('parses Arabic send SMS', () {
      final result = parser.parse(
        'تم تحويل 100 جنيه لرقم 01566666666 رصيدك الحالي 700 جنيه رقم العملية 445566',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.wePay);
      expect(result.type, TransactionType.send);
      expect(result.amount, 100);
      expect(result.counterpartyNumber, '01566666666');
      expect(result.referenceNumber, '445566');
    });
  });
}
