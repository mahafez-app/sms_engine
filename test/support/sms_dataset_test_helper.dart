import 'dart:convert';
import 'dart:io';

import 'package:mahafez_core/mahafez_core.dart';

final class SmsDatasetMessage {
  const SmsDatasetMessage({
    required this.sender,
    required this.body,
    required this.date,
    required this.subscriptionId,
    required this.referenceKey,
    required this.expectedType,
  });

  final String sender;
  final String body;
  final DateTime date;
  final String subscriptionId;
  final String referenceKey;
  final TransactionType? expectedType;
}

final class SmsDatasetLoader {
  const SmsDatasetLoader._();

  static List<SmsDatasetMessage> load(String path) {
    final raw = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
    final messages = <SmsDatasetMessage>[];

    for (final group in raw.cast<Map<String, dynamic>>()) {
      final sender = group['_address'] as String;
      for (final item
          in (group['messages'] as List).cast<Map<String, dynamic>>()) {
        final body = item['_body'] as String? ?? '';
        final date = DateTime.fromMillisecondsSinceEpoch(
          int.parse(item['_date'] as String),
        );
        final subscriptionId = item['_sub_id'] as String? ?? '';

        messages.add(
          SmsDatasetMessage(
            sender: sender,
            body: body,
            date: date,
            subscriptionId: subscriptionId,
            referenceKey: _referenceKey(item, body),
            expectedType: _expectedType(sender: sender, body: body),
          ),
        );
      }
    }

    return messages;
  }

  static String _referenceKey(Map<String, dynamic> item, String body) {
    final operationMatch = RegExp(
      r'رقم\s+(?:العملية|مرجعي)\s*[:\-]?\s*(\d+)',
    ).firstMatch(body);
    if (operationMatch != null) {
      return operationMatch.group(1)!;
    }

    final englishRefMatch = RegExp(
      r'Ref(?:\s*No\.?)?\s*[:\-]?\s*(\d+)',
    ).firstMatch(body);
    if (englishRefMatch != null) {
      return englishRefMatch.group(1)!;
    }

    return '${item['_date']}:${body.hashCode}';
  }

  static TransactionType? _expectedType({
    required String sender,
    required String body,
  }) {
    if (sender == 'VF-Cash') {
      if (body.contains('تم استلام مبلغ') || body.contains('Received EGP')) {
        return TransactionType.receive;
      }
      if (body.contains('تم تحويل ')) {
        return TransactionType.send;
      }
      return null;
    }

    if (sender == 'BanK-AlAhly') {
      if (body.contains('تم إضافة تحويل لحظي لحسابكم')) {
        return TransactionType.receive;
      }
      if (body.contains('تم تنفيذ تحويل لحظي من حسابكم')) {
        return TransactionType.send;
      }
    }

    return null;
  }
}
