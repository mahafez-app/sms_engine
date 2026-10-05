import 'package:mahafez_core/mahafez_core.dart';
import '../patterns/sms_patterns.dart';
import 'sms_parser.dart';

final class VodafoneCashSmsParser extends SmsParser {
  const VodafoneCashSmsParser();

  @override
  WalletProvider get provider => WalletProvider.vodafoneCash;

  @override
  List<String> get senderIds => [
    'VF-Cash',
    'VFCash',
    'Vodafone-Cash',
    'VodafoneCash',
  ];

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
