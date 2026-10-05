import 'dart:async';
import 'dart:developer';

import 'package:another_telephony/telephony.dart';

import '../matcher/sms_wallet_matcher.dart';
import '../models/sms_transaction_event.dart';
import '../models/sms_wallet_candidate.dart';
import '../models/sms_wallet_match_result.dart';
import '../registry/sms_parser_registry.dart';
import '../utils/sms_message_extension.dart';
import 'sms_parsing_service.dart';

abstract interface class SmsEngineService {
  Stream<SmsTransactionEvent> get onTransactionDetected;
  bool get isListening;

  void startListening();
  void stopListening();
  void updateWallets(List<SmsWalletCandidate> wallets);
}

class TelephonySmsEngineService implements SmsEngineService {
  TelephonySmsEngineService({this.telephony});

  final Telephony? telephony;
  Telephony get _instance => telephony ?? Telephony.instance;

  static const _tag = 'SmsEngineService';

  final _controller = StreamController<SmsTransactionEvent>.broadcast();
  List<SmsWalletCandidate> _wallets = const [];
  bool _isListening = false;

  @override
  Stream<SmsTransactionEvent> get onTransactionDetected => _controller.stream;

  @override
  bool get isListening => _isListening;

  @override
  void updateWallets(List<SmsWalletCandidate> wallets) {
    _wallets = List.unmodifiable(wallets);
  }

  @override
  void startListening() {
    if (_isListening) return;

    try {
      _instance.listenIncomingSms(
        onNewMessage: _handleForegroundMessage,
        listenInBackground: false,
      );
      _isListening = true;
      log('Foreground SMS listener registered.', name: _tag);
    } catch (e, st) {
      log('Failed to register SMS listener: $e', name: _tag, error: e, stackTrace: st);
    }
  }

  @override
  void stopListening() {
    _isListening = false;
  }

  void _handleForegroundMessage(SmsMessage message) {
    final sender = message.address;
    final body = message.body;
    if (sender == null || body == null) return;

    if (SmsParserRegistry.resolve(sender) == null) {
      return;
    }

    final receivedAt = message.receivedAt;
    final parseResult = SmsParsingService.parseRaw(
      sender: sender,
      message: body,
      smsReceivedAt: receivedAt,
    );

    if (parseResult == null) return;

    SmsWalletCandidate? matchedWallet;
    final candidateWallets = _wallets.where((w) {
      // Filter wallets by provider if needed or pass all candidates
      return true;
    }).toList();

    if (candidateWallets.isNotEmpty) {
      final input = SmsWalletMatchInput(
        amount: parseResult.amount,
        transactionType: parseResult.type,
        parsedBalance: parseResult.balance,
        counterpartyNumber: parseResult.counterpartyNumber,
        mentionedPhoneNumbers: parseResult.mentionedPhoneNumbers,
      );

      final matchResult = SmsWalletMatcher.resolve(
        wallets: candidateWallets,
        input: input,
      );

      if (matchResult is SmsWalletMatchedResult<SmsWalletCandidate>) {
        matchedWallet = matchResult.wallet;
      }
    }

    final event = SmsTransactionEvent(
      sender: sender,
      rawBody: body,
      receivedAt: receivedAt,
      parseResult: parseResult,
      matchedWallet: matchedWallet,
    );

    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
