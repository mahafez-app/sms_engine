import 'package:mahafez_core/mahafez_core.dart';

final class SmsPhoneNumberExtractor {
  SmsPhoneNumberExtractor._();

  static final RegExp _egyptianMobilePattern = RegExp(
    r'(?<!\d)(?:\+?2|002)?01[0125](?:[\s\-]?\d){8}(?!\d)',
  );

  static List<String> extractEgyptianMobileNumbers(String message) {
    final normalizedNumbers = <String>{};

    for (final match in _egyptianMobilePattern.allMatches(message)) {
      final normalizedPhoneNumber = EgyptianPhoneNumber.tryNormalizeMobile(
        match.group(0),
      );
      if (normalizedPhoneNumber != null) {
        normalizedNumbers.add(normalizedPhoneNumber);
      }
    }

    return normalizedNumbers.toList(growable: false);
  }
}
