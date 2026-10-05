import 'package:mahafez_core/mahafez_core.dart';
import '../patterns/sms_patterns.dart';
import 'sms_parser.dart';

final class EtisalatCashSmsParser extends SmsParser {
  const EtisalatCashSmsParser();

  @override
  WalletProvider get provider => WalletProvider.etisalatCash;

  @override
  List<String> get senderIds =>
      ['Etisalat', 'E-Cash', 'ECash', 'Etisalat-Cash', 'EtisalatCash'];

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
        SmsPatterns.refNumberAr,
        SmsPatterns.refEn,
      ];
}
