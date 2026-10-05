import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:sms_engine/sms_engine.dart';

void main() {
  const parser = VodafoneCashSmsParser();
  final now = DateTime(2026, 4, 20, 12);

  group('VodafoneCashSmsParser Tests', () {
    test('ignores insufficient balance alerts', () {
      final result = parser.parse(
        'لا يوجد رصيد كاف في حسابك. يمكنك تحويل 3652 جنية فقط بعد خصم 15 ج رسوم تحويل; رقم العملية 019289183176',
        now,
      );

      expect(result, isNull);
    });

    test('parses successful send sms', () {
      final result = parser.parse(
        'تم تحويل 6750 جنيه لرقم 01020565524 مصاريف الخدمة 1 جنيه '
        'رصيد حسابك فى فودافون كاش الحالي 7462.66. '
        'تاريخ العملية: 16:23 26-04-20 رقم العملية: 019320913232',
        now,
      );

      expect(result, isNotNull);
      expect(result!.type, TransactionType.send);
      expect(result.amount, 6750);
      expect(result.counterpartyNumber, '01020565524');
      expect(result.balance, 7462.66);
    });

    test('parses receive sms in Arabic', () {
      final result = parser.parse(
        'تم استلام مبلغ 1500 جنيه من رقم 01012345678 رصيدك الحالي 4500.50 جنيه رقم العملية 0192837465',
        now,
      );

      expect(result, isNotNull);
      expect(result!.type, TransactionType.receive);
      expect(result.amount, 1500);
      expect(result.counterpartyNumber, '01012345678');
      expect(result.balance, 4500.50);
      expect(result.referenceNumber, '0192837465');
    });

    test('parses English format correctly', () {
      final result = parser.parse(
        'Received EGP 500 from 01099887766. Available Balance: 3200. Ref: 9876543210',
        now,
      );

      expect(result, isNotNull);
      expect(result!.type, TransactionType.receive);
      expect(result.amount, 500);
      expect(result.counterpartyNumber, '01099887766');
      expect(result.balance, 3200);
    });
  });
}
