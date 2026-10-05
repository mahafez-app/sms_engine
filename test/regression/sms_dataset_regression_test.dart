import 'package:flutter_test/flutter_test.dart';
import 'package:mahafez_sms_engine/mahafez_sms_engine.dart';

import '../support/sms_dataset_test_helper.dart';

void main() {
  group('SMS dataset parsing', () {
    test(
      'different-provider dataset matches only expected send/receive SMS',
      () {
        final messages = SmsDatasetLoader.load(
          'data/sms-different-providers-device_grouped_by_address.filtered.json',
        );

        for (final message in messages) {
          final result = SmsParsingService.parseRaw(
            sender: message.sender,
            message: message.body,
            smsReceivedAt: message.date,
          );

          if (message.expectedType == null) {
            expect(
              result,
              isNull,
              reason: 'Unexpected parse for ${message.referenceKey}',
            );
            continue;
          }

          expect(result, isNotNull, reason: 'Missed ${message.referenceKey}');
          expect(
            result!.type,
            message.expectedType,
            reason: 'Wrong type for ${message.referenceKey}',
          );
        }
      },
    );

    test('same-provider dataset matches only expected send/receive SMS', () {
      final messages = SmsDatasetLoader.load(
        'data/sms-same-providers-device_grouped_by_address.filtered.json',
      );

      for (final message in messages) {
        final result = SmsParsingService.parseRaw(
          sender: message.sender,
          message: message.body,
          smsReceivedAt: message.date,
        );

        if (message.expectedType == null) {
          expect(
            result,
            isNull,
            reason: 'Unexpected parse for ${message.referenceKey}',
          );
          continue;
        }

        expect(result, isNotNull, reason: 'Missed ${message.referenceKey}');
        expect(
          result!.type,
          message.expectedType,
          reason: 'Wrong type for ${message.referenceKey}',
        );
      }
    });
  });

  group('Same-provider history routing', () {
    test(
      'routes last-week VF history to the correct wallet on the same device',
      () {
        final messages = SmsDatasetLoader.load(
          'data/sms-same-providers-device_grouped_by_address.filtered.json',
        );
        final records = messages
            .where((message) => message.expectedType != null)
            .map((message) {
              final result = SmsParsingService.parseRaw(
                sender: message.sender,
                message: message.body,
                smsReceivedAt: message.date,
              );
              expect(
                result,
                isNotNull,
                reason: 'Missed ${message.referenceKey}',
              );
              return (
                createdAt: message.date,
                body: message.referenceKey,
                parseResult: result!,
              );
            })
            .toList(growable: false);

        final walletPhones = const ['01018683900', '01020902196'];
        final walletOneHistory = InboxSmsHistoryMatcher.resolveWalletHistory(
          records: records,
          targetPhoneNumber: walletPhones.first,
          sameProviderPhoneNumbers: walletPhones,
        );
        final walletTwoHistory = InboxSmsHistoryMatcher.resolveWalletHistory(
          records: records,
          targetPhoneNumber: walletPhones.last,
          sameProviderPhoneNumbers: walletPhones,
        );

        final expectedWalletOne = messages
            .where(
              (message) =>
                  message.expectedType != null && message.subscriptionId == '1',
            )
            .map((message) => message.referenceKey)
            .toSet();
        final expectedWalletTwo = messages
            .where(
              (message) =>
                  message.expectedType != null && message.subscriptionId == '2',
            )
            .map((message) => message.referenceKey)
            .toSet();

        expect(
          walletOneHistory.map((record) => record.body).toSet(),
          expectedWalletOne,
        );
        expect(
          walletTwoHistory.map((record) => record.body).toSet(),
          expectedWalletTwo,
        );
      },
    );
  });
}
