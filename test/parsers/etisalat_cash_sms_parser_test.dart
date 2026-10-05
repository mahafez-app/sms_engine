import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:sms_engine/sms_engine.dart';

void main() {
  const parser = EtisalatCashSmsParser();
  final now = DateTime(2026, 4, 20, 12);

  group('EtisalatCashSmsParser Tests', () {
    test('parses Arabic receive SMS', () {
      final result = parser.parse(
        'تم استلام 750 جنيه من رقم 01111111111 رصيدك الحالي 1500 جنيه رقم المرجع 456789',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.etisalatCash);
      expect(result.type, TransactionType.receive);
      expect(result.amount, 750);
      expect(result.counterpartyNumber, '01111111111');
      expect(result.referenceNumber, '456789');
    });

    test('parses Arabic send SMS', () {
      final result = parser.parse(
        'تم تحويل 300 جنيه لرقم 01122222222 رصيدك الحالي 1200 جنيه Ref: 98712345',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.etisalatCash);
      expect(result.type, TransactionType.send);
      expect(result.amount, 300);
      expect(result.counterpartyNumber, '01122222222');
      expect(result.referenceNumber, '98712345');
    });
  });
}
