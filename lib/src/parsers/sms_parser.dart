import 'dart:developer';

import 'package:mahafez_core/mahafez_core.dart';
import '../matcher/sms_pattern_matcher.dart';
import '../matcher/sms_phone_number_extractor.dart';
import '../models/sms_parse_result.dart';
import '../patterns/sms_patterns.dart';

abstract class SmsParser {
  const SmsParser();

  WalletProvider get provider;
  List<String> get senderIds;

  List<RegExp> get receivePatterns;
  List<RegExp> get sendPatterns;
  List<RegExp> get refPatterns;

  SmsParseResult? parse(
    String message,
    DateTime smsReceivedAt, {
    bool useContentDate = false,
  }) {
    final match = SmsPatternMatcher.match(
      message,
      receivePatterns: receivePatterns,
      sendPatterns: sendPatterns,
    );
    if (match == null) return null;

    log(
      'Parsing SMS from ${senderIds.first} with system date: $smsReceivedAt',
      name: 'SmsParser',
    );

    final createdAt = useContentDate
        ? extractDateTime(message, smsReceivedAt)
        : smsReceivedAt;

    return SmsParseResult(
      amount: match.amount,
      type: match.type,
      createdAt: createdAt,
      provider: provider,
      counterpartyNumber: match.counterpartyNumber,
      referenceNumber: extractRef(message),
      balance: extractBalance(message) ?? match.balance,
      mentionedPhoneNumbers:
          SmsPhoneNumberExtractor.extractEgyptianMobileNumbers(message),
    );
  }

  String? extractRef(String message) {
    for (final pattern in refPatterns) {
      final m = pattern.firstMatch(message);
      if (m != null) {
        for (int i = m.groupCount; i >= 1; i--) {
          if (m.group(i) != null) return m.group(i);
        }
      }
    }
    return null;
  }

  double? extractBalance(String message) {
    final m =
        SmsPatterns.balanceAr.firstMatch(message) ??
        SmsPatterns.balanceEn.firstMatch(message);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '').trim());
  }

  DateTime extractDateTime(String message, DateTime defaultDate) {
    int day = defaultDate.day;
    int month = defaultDate.month;
    int year = defaultDate.year;
    bool dateFound = false;

    // 1. Try ISO (YYYY-MM-DD or YYYY/MM/DD)
    final iso = SmsPatterns.dateIso.firstMatch(message);
    if (iso != null) {
      year = int.tryParse(iso.group(1) ?? '') ?? year;
      month = int.tryParse(iso.group(2) ?? '') ?? month;
      day = int.tryParse(iso.group(3) ?? '') ?? day;
      dateFound = true;
    }

    // 2. Try English (MMM DD, YYYY)
    if (!dateFound) {
      final eng = SmsPatterns.dateEnglish.firstMatch(message);
      if (eng != null) {
        month = _monthToNumber(eng.group(1) ?? '');
        day = int.tryParse(eng.group(2) ?? '') ?? day;
        year = int.tryParse(eng.group(3) ?? '') ?? year;
        dateFound = true;
      }
    }

    // 3. Try short dates (DD-MM-YYYY, DD-MM-YY, or YY-MM-DD)
    if (!dateFound) {
      final shortDate = SmsPatterns.dateShort.firstMatch(message);
      if (shortDate != null) {
        final a = int.tryParse(shortDate.group(1) ?? '') ?? 0;
        final m = int.tryParse(shortDate.group(2) ?? '') ?? 0;
        final cStr = shortDate.group(3) ?? '';
        final c = int.tryParse(cStr) ?? 0;

        if (cStr.length == 4) {
          // Unambiguous DD-MM-YYYY
          day = a;
          month = m;
          year = c;
          dateFound = true;
        } else {
          // Ambiguous: both A and C are 2 digits (DD-MM-YY vs YY-MM-DD).
          // We figure out which one is the year by comparing with current year.
          final currentYear2Digit = DateTime.now().year % 100;

          bool aIsYear = false;

          // If one is clearly a day (>31 is impossible for a day in a valid date)
          if (a > 31) {
            aIsYear = true;
          } else if (c > 31) {
            aIsYear = false;
          } else {
            // Distance heuristic: which number is closer to the current year?
            final distA = (a - currentYear2Digit).abs();
            final distC = (c - currentYear2Digit).abs();

            if (distA < distC) {
              aIsYear = true;
            } else if (distC < distA) {
              aIsYear = false;
            } else {
              // Equidistant. Default to YY-MM-DD (Vodafone Cash standard).
              // Vodafone Cash Arabic is the most notable user of 2-digit years.
              aIsYear = true;
            }
          }

          if (aIsYear) {
            year = 2000 + a;
            month = m;
            day = c;
          } else {
            year = 2000 + c;
            month = m;
            day = a;
          }
          dateFound = true;
        }
      }
    }

    int hour = defaultDate.hour;
    int minute = defaultDate.minute;
    int second = defaultDate.second;

    final timeMatch = SmsPatterns.timePattern.firstMatch(message);
    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1) ?? '') ?? hour;
      minute = int.tryParse(timeMatch.group(2) ?? '') ?? minute;
      second = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;

      final amPm = timeMatch.group(4)?.toUpperCase();
      if (amPm == 'PM' && hour < 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;
    }

    try {
      final result = DateTime(year, month, day, hour, minute, second);
      // Basic sanity check: if the date is way in the future or past, fallback.
      if (result.year < 2020 || result.year > 2035) return defaultDate;
      return result;
    } catch (_) {
      return defaultDate;
    }
  }

  int _monthToNumber(String month) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }
}
