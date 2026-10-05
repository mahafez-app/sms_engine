import 'package:mahafez_core/mahafez_core.dart';
import '../patterns/sms_patterns.dart';
import 'sms_parser.dart';

final class OrangeMoneySmsParser extends SmsParser {
  const OrangeMoneySmsParser();

  @override
  WalletProvider get provider => WalletProvider.orangeMoney;

  @override
  List<String> get senderIds =>
      ['Orange-Cash', 'OrangeCash', 'Orange-Money', 'OrangeMoney'];

  @override
  List<RegExp> get receivePatterns => [
        SmsPatterns.arReceiveFromNumber,
        SmsPatterns.arBankReceive,
        SmsPatterns.enReceiveFromNumber,
        SmsPatterns.enTransferReceivedFromNumber,
      ];

  @override
  List<RegExp> get sendPatterns => [
        SmsPatterns.arSendToNumber,
        SmsPatterns.arBankSend,
        SmsPatterns.enSendToNumber,
        SmsPatterns.enTransferSentToNumber,
      ];

  @override
  List<RegExp> get refPatterns => [
        SmsPatterns.refCodeAr,
        SmsPatterns.refOperationAr,
        SmsPatterns.refNumberAr,
        SmsPatterns.refEn,
      ];
}
