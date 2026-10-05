import 'package:mahafez_core/mahafez_core.dart';
import '../patterns/sms_patterns.dart';
import 'sms_parser.dart';

final class WePaySmsParser extends SmsParser {
  const WePaySmsParser();

  @override
  WalletProvider get provider => WalletProvider.wePay;

  @override
  List<String> get senderIds => ['WE-Pay', 'WEPay', 'WE'];

  @override
  List<RegExp> get receivePatterns => [
        SmsPatterns.arReceiveFromNumber,
        SmsPatterns.enReceiveFromNumber,
        SmsPatterns.enTransferReceivedFromNumber,
      ];

  @override
  List<RegExp> get sendPatterns => [
        SmsPatterns.arSendToNumber,
        SmsPatterns.enSendToNumber,
        SmsPatterns.enTransferSentToNumber,
      ];

  @override
  List<RegExp> get refPatterns => [
        SmsPatterns.refOperationAr,
        SmsPatterns.refEn,
      ];
}
