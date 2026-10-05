import 'package:mahafez_core/mahafez_core.dart';
import '../patterns/sms_patterns.dart';
import 'sms_parser.dart';

final class InstaPaySmsParser extends SmsParser {
  const InstaPaySmsParser();

  @override
  WalletProvider get provider => WalletProvider.instaPay;

  @override
  List<String> get senderIds => [
    'InstaPay',
    'Insta-Pay',
    'BanK-AlAhly',
    'BankAlAhly',
    'NBE',
    'CIB',
    'Banque-Misr',
    'BanqueMisr',
    'QNB',
    'AAIB',
    'HSBC',
    'Fawry',
  ];

  @override
  List<RegExp> get receivePatterns => [
    SmsPatterns.arBankReceive,
    SmsPatterns.enTransferReceivedFromNumber,
  ];

  @override
  List<RegExp> get sendPatterns => [
    SmsPatterns.arBankSend,
    SmsPatterns.enTransferSentToNumber,
  ];

  @override
  List<RegExp> get refPatterns => [
    SmsPatterns.refBankAr,
    SmsPatterns.refBeforeDateAr,
    SmsPatterns.refEn,
  ];
}
