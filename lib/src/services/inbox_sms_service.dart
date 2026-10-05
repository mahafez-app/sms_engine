import 'dart:developer';

import 'package:another_telephony/telephony.dart';
import 'package:mahafez_core/mahafez_core.dart';

import '../matcher/inbox_sms_history_matcher.dart';
import '../models/parsed_inbox_sms_record.dart';
import '../registry/sms_parser_registry.dart';
import 'sms_parsing_service.dart';

abstract interface class InboxSmsService {
  Future<double?> getLatestBalance({
    required WalletProvider provider,
    required String targetPhoneNumber,
    required List<String> sameProviderWalletPhoneNumbers,
    Map<String, double> sameProviderWalletBalances = const {},
  });

  Future<List<ParsedInboxSmsRecord>> getMatchedHistoricalRecords({
    required WalletProvider provider,
    required String phoneNumber,
    required List<String> sameProviderWalletPhoneNumbers,
    Map<String, double> sameProviderWalletBalances = const {},
    DateTime? sinceDate,
  });

  Future<List<SmsMessage>> getProviderMessages({
    required WalletProvider provider,
    required List<String> senderIds,
    DateTime? sinceDate,
  });

  List<ParsedInboxSmsRecord> parseRecords(
    List<SmsMessage> messages, {
    DateTime? sinceDate,
  });
}

class InboxSmsServiceImpl implements InboxSmsService {
  const InboxSmsServiceImpl({this.telephony});

  final Telephony? telephony;
  Telephony get _instance => telephony ?? Telephony.instance;

  static const _tag = 'InboxSmsService';

  @override
  Future<double?> getLatestBalance({
    required WalletProvider provider,
    required String targetPhoneNumber,
    required List<String> sameProviderWalletPhoneNumbers,
    Map<String, double> sameProviderWalletBalances = const {},
  }) async {
    final parser = SmsParserRegistry.resolveByProvider(provider);
    if (parser == null) {
      log('No parser found for provider ${provider.toValue}', name: _tag);
      return null;
    }

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final thirtyDaysAgoMs = thirtyDaysAgo.millisecondsSinceEpoch;

      final messages = await _instance.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(
          SmsColumn.DATE,
        ).greaterThan(thirtyDaysAgoMs.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final filteredMessages = messages
          .where((message) {
            final address = message.address;
            if (address == null) return false;
            return parser.senderIds.any(
              (id) => id.toLowerCase() == address.toLowerCase(),
            );
          })
          .toList(growable: false);

      final records = parseRecords(filteredMessages);
      final balance = InboxSmsHistoryMatcher.resolveLatestBalance(
        records: records,
        targetPhoneNumber: targetPhoneNumber,
        sameProviderPhoneNumbers: sameProviderWalletPhoneNumbers,
        knownWalletBalances: sameProviderWalletBalances,
      );
      if (balance != null) {
        log(
          'Found balance $balance for ${provider.toValue} in SMS history',
          name: _tag,
        );
        return balance;
      }
    } catch (e, st) {
      log(
        'Failed to query inbox for provider ${provider.toValue}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }

    return null;
  }

  @override
  Future<List<ParsedInboxSmsRecord>> getMatchedHistoricalRecords({
    required WalletProvider provider,
    required String phoneNumber,
    required List<String> sameProviderWalletPhoneNumbers,
    Map<String, double> sameProviderWalletBalances = const {},
    DateTime? sinceDate,
  }) async {
    final parser = SmsParserRegistry.resolveByProvider(provider);
    if (parser == null) return const [];

    final messages = await getProviderMessages(
      provider: provider,
      senderIds: parser.senderIds,
      sinceDate: sinceDate,
    );
    final records = parseRecords(messages, sinceDate: sinceDate);
    final matchedRecords = InboxSmsHistoryMatcher.resolveWalletHistory(
      records: records,
      targetPhoneNumber: phoneNumber,
      sameProviderPhoneNumbers: sameProviderWalletPhoneNumbers,
      knownWalletBalances: sameProviderWalletBalances,
    );

    if (matchedRecords.isNotEmpty) {
      log(
        'Recovered ${matchedRecords.length} historical SMS records for provider ${provider.toValue}',
        name: _tag,
      );
    }

    return matchedRecords;
  }

  @override
  Future<List<SmsMessage>> getProviderMessages({
    required WalletProvider provider,
    required List<String> senderIds,
    DateTime? sinceDate,
  }) async {
    if (senderIds.isEmpty) return const [];
    final effectiveSinceDate =
        sinceDate ?? DateTime.now().subtract(const Duration(days: 7));
    final sinceMs = effectiveSinceDate.millisecondsSinceEpoch;
    final filter = SmsFilter.where(SmsColumn.ADDRESS).equals(senderIds.first);

    for (final id in senderIds.skip(1)) {
      filter.or(SmsColumn.ADDRESS).equals(id);
    }

    final messages = await _instance.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: filter.and(SmsColumn.DATE).greaterThan('$sinceMs'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    return messages
        .where((message) {
          final address = message.address;
          if (address == null) return false;
          return senderIds.any(
            (id) => id.toLowerCase() == address.toLowerCase(),
          );
        })
        .toList(growable: false);
  }

  @override
  List<ParsedInboxSmsRecord> parseRecords(
    List<SmsMessage> messages, {
    DateTime? sinceDate,
  }) {
    final records = <ParsedInboxSmsRecord>[];

    for (final message in messages) {
      final sender = message.address;
      final body = message.body;
      if (sender == null || body == null) continue;

      final createdAt = _resolveMessageDate(message.date);
      if (sinceDate != null && !createdAt.isAfter(sinceDate)) continue;

      final parseResult = SmsParsingService.parseRaw(
        sender: sender,
        message: body,
        smsReceivedAt: createdAt,
      );
      if (parseResult == null) continue;

      records.add((createdAt: createdAt, body: body, parseResult: parseResult));
    }

    return records;
  }

  DateTime _resolveMessageDate(int? timestampMs) {
    if (timestampMs == null) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(timestampMs);
  }
}
