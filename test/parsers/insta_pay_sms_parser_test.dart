import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_core/mahafez_core.dart';
import 'package:sms_engine/sms_engine.dart';

void main() {
  const parser = InstaPaySmsParser();
  final now = DateTime(2026, 4, 20, 12);

  group('InstaPaySmsParser Tests', () {
    test('parses bank receive SMS', () {
      final result = parser.parse(
        'تم إضافة تحويل لحظي لحسابكم بمبلغ 2500 جنيه رقم مرجعي 643111494336 يوم 20-04-2026',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.instaPay);
      expect(result.type, TransactionType.receive);
      expect(result.amount, 2500);
      expect(result.referenceNumber, '643111494336');
    });

    test('parses bank send SMS', () {
      final result = parser.parse(
        'تم تنفيذ تحويل لحظي من حسابكم بمبلغ 1200 جنيه رقم مرجعي 778899001122 يوم 20-04-2026',
        now,
      );

      expect(result, isNotNull);
      expect(result!.provider, WalletProvider.instaPay);
      expect(result.type, TransactionType.send);
      expect(result.amount, 1200);
      expect(result.referenceNumber, '778899001122');
    });
  });
}
