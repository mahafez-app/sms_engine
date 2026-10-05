import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

import '../models/pending_sms_retry_item.dart';

/// Service responsible for managing the queue of failed SMS processing attempts.
///
/// It stores raw SMS data in a Hive box and provides methods to enqueue,
/// retry, and remove items.
final class PendingSmsRetryService {
  PendingSmsRetryService({required this.box});

  final Box<String> box;
  static bool _isRetrying = false;

  static const _tag = 'PendingSmsRetryService';

  /// Adds an SMS to the retry queue.
  ///
  /// If an item with the same [id] already exists, it updates the existing item
  /// (e.g. updating the error and incrementing retry count) instead of
  /// creating a duplicate.
  Future<void> enqueue(PendingSmsRetryItem item) async {
    final existingJson = box.get(item.id);
    if (existingJson != null) {
      try {
        final existingItem = PendingSmsRetryItem.fromJson(
          jsonDecode(existingJson) as Map<String, dynamic>,
        );
        final updatedItem = existingItem.copyWith(
          lastError: item.lastError,
          retryCount: existingItem.retryCount + 1,
          updatedAt: DateTime.now(),
        );
        await box.put(item.id, jsonEncode(updatedItem.toJson()));
        log('Updated existing retry item: ${item.id}', name: _tag);
        return;
      } catch (e) {
        log('Failed to update existing retry item: $e', name: _tag);
      }
    }

    await box.put(item.id, jsonEncode(item.toJson()));
    log('Enqueued new retry item: ${item.id}', name: _tag);
  }

  /// Removes an item from the queue after successful processing.
  Future<void> remove(String id) async {
    await box.delete(id);
    log('Removed retry item from queue: $id', name: _tag);
  }

  /// Marks a retry attempt as failed, updating the item in the queue.
  Future<void> markFailure(String id, String error) async {
    final json = box.get(id);
    if (json == null) return;

    try {
      final item = PendingSmsRetryItem.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      final updatedItem = item.copyWith(
        lastError: error,
        retryCount: item.retryCount + 1,
        updatedAt: DateTime.now(),
      );
      await box.put(id, jsonEncode(updatedItem.toJson()));
      log(
        'Marked failure for item: $id (Retry: ${updatedItem.retryCount})',
        name: _tag,
      );
    } catch (e) {
      log('Failed to mark failure for item $id: $e', name: _tag);
    }
  }

  /// Iterates through all pending items and attempts to process them.
  ///
  /// [processItem] is a callback that performs the actual processing (wallet resolution,
  /// parsing, saving). It should return true on success, false on failure.
  Future<void> retryPending({
    required Future<bool> Function(PendingSmsRetryItem item) processItem,
  }) async {
    if (_isRetrying) return;
    if (box.isEmpty) return;

    _isRetrying = true;
    log('Starting retry of ${box.length} pending items', name: _tag);

    try {
      final items = <PendingSmsRetryItem>[];
      final keys = box.keys.toList(growable: false);

      for (final key in keys) {
        final json = box.get(key);
        if (json == null) continue;

        try {
          items.add(
            PendingSmsRetryItem.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          log('Error decoding retry item $key: $e', name: _tag);
        }
      }

      items.sort((left, right) {
        final receivedAtComparison = left.smsReceivedAt.compareTo(
          right.smsReceivedAt,
        );
        if (receivedAtComparison != 0) return receivedAtComparison;
        return left.createdAt.compareTo(right.createdAt);
      });

      for (final item in items) {
        try {
          log(
            'Retrying item: ${item.id} (Attempt: ${item.retryCount + 1})',
            name: _tag,
          );

          final success = await processItem(item);

          if (success) {
            await remove(item.id);
          }
        } catch (e) {
          log('Error processing retry item ${item.id}: $e', name: _tag);
        }
      }
    } finally {
      _isRetrying = false;
      log('Finished retry processing', name: _tag);
    }
  }

  /// Generates a deterministic key for an SMS to deduplicate queue items.
  static String generateQueueKey({
    required String sender,
    required String body,
    required DateTime receivedAt,
  }) {
    final s = sender.trim().toLowerCase();
    final b = body.trim();
    final t = receivedAt.millisecondsSinceEpoch;
    return '${s}_${b.hashCode}_$t';
  }
}
