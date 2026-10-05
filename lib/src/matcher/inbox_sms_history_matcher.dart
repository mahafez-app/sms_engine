import 'package:mahafez_core/mahafez_core.dart';
import '../models/parsed_inbox_sms_record.dart';
import '../models/sms_parse_result.dart';

final class InboxSmsHistoryMatcher {
  const InboxSmsHistoryMatcher._();

  static List<ParsedInboxSmsRecord> resolveWalletHistory({
    required List<ParsedInboxSmsRecord> records,
    required String targetPhoneNumber,
    required List<String> sameProviderPhoneNumbers,
    Map<String, double> knownWalletBalances = const {},
  }) {
    final resolution = _resolve(
      records: records,
      targetPhoneNumber: targetPhoneNumber,
      sameProviderPhoneNumbers: sameProviderPhoneNumbers,
      knownWalletBalances: knownWalletBalances,
    );
    return resolution.targetRecords;
  }

  static double? resolveLatestBalance({
    required List<ParsedInboxSmsRecord> records,
    required String targetPhoneNumber,
    required List<String> sameProviderPhoneNumbers,
    Map<String, double> knownWalletBalances = const {},
  }) {
    final resolution = _resolve(
      records: records,
      targetPhoneNumber: targetPhoneNumber,
      sameProviderPhoneNumbers: sameProviderPhoneNumbers,
      knownWalletBalances: knownWalletBalances,
    );

    for (final record in resolution.targetRecords.reversed) {
      final balance = record.parseResult.balance;
      if (balance != null) {
        return balance;
      }
    }

    return null;
  }

  static _HistoryResolution _resolve({
    required List<ParsedInboxSmsRecord> records,
    required String targetPhoneNumber,
    required List<String> sameProviderPhoneNumbers,
    Map<String, double> knownWalletBalances = const {},
  }) {
    final normalizedTargetPhoneNumber = EgyptianPhoneNumber.tryNormalizeMobile(
      targetPhoneNumber,
    );
    if (normalizedTargetPhoneNumber == null) {
      return const _HistoryResolution(targetRecords: <ParsedInboxSmsRecord>[]);
    }

    final normalizedProviderPhoneNumbers =
        sameProviderPhoneNumbers
            .map(EgyptianPhoneNumber.tryNormalizeMobile)
            .whereType<String>()
            .toSet()
          ..add(normalizedTargetPhoneNumber);

    final sortedRecords = List<ParsedInboxSmsRecord>.from(records)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    final mentions = sortedRecords
        .map(
          (record) => _resolveMention(
            parseResult: record.parseResult,
            normalizedTargetPhoneNumber: normalizedTargetPhoneNumber,
            normalizedProviderPhoneNumbers: normalizedProviderPhoneNumbers,
          ),
        )
        .toList(growable: false);

    if (normalizedProviderPhoneNumbers.length <= 1) {
      final targetRecords = <ParsedInboxSmsRecord>[
        for (var index = 0; index < sortedRecords.length; index += 1)
          if (mentions[index] != _WalletMention.other) sortedRecords[index],
      ];
      return _HistoryResolution(targetRecords: targetRecords);
    }

    final targetIndexes = <int>{
      for (var index = 0; index < mentions.length; index += 1)
        if (mentions[index] == _WalletMention.target) index,
    };
    final otherIndexes = <int>{
      for (var index = 0; index < mentions.length; index += 1)
        if (mentions[index] == _WalletMention.other) index,
    };

    // Seed ambiguous records via backward balance walk. This bootstraps
    // attribution when no message explicitly mentions the wallet's own phone —
    // the common case for Egyptian providers in multi-wallet scenarios.
    if (knownWalletBalances.isNotEmpty) {
      final normalizedKnownBalances = <String, double>{};
      for (final entry in knownWalletBalances.entries) {
        final phone = EgyptianPhoneNumber.tryNormalizeMobile(entry.key);
        if (phone != null) normalizedKnownBalances[phone] = entry.value;
      }
      _seedFromKnownWalletBalances(
        records: sortedRecords,
        mentions: mentions,
        normalizedTargetPhoneNumber: normalizedTargetPhoneNumber,
        normalizedKnownWalletBalances: normalizedKnownBalances,
        targetIndexes: targetIndexes,
        otherIndexes: otherIndexes,
      );
    }

    var changed = true;
    while (changed) {
      changed = false;

      for (var index = 0; index < sortedRecords.length; index += 1) {
        if (mentions[index] != _WalletMention.ambiguous ||
            targetIndexes.contains(index) ||
            otherIndexes.contains(index)) {
          continue;
        }

        final chainsToTarget = _chainsWithNearestAttributedRecords(
          index: index,
          attributedIndexes: targetIndexes,
          records: sortedRecords,
        );
        final chainsToOther = _chainsWithNearestAttributedRecords(
          index: index,
          attributedIndexes: otherIndexes,
          records: sortedRecords,
        );

        if (chainsToTarget == chainsToOther) {
          continue;
        }

        if (chainsToTarget) {
          changed = targetIndexes.add(index) || changed;
          continue;
        }

        changed = otherIndexes.add(index) || changed;
      }
    }

    final targetRecords = <ParsedInboxSmsRecord>[
      for (var index = 0; index < sortedRecords.length; index += 1)
        if (targetIndexes.contains(index)) sortedRecords[index],
    ];

    return _HistoryResolution(targetRecords: targetRecords);
  }

  static _WalletMention _resolveMention({
    required SmsParseResult parseResult,
    required String normalizedTargetPhoneNumber,
    required Set<String> normalizedProviderPhoneNumbers,
  }) {
    final targetMentioned = parseResult.mentionedPhoneNumbers.contains(
      normalizedTargetPhoneNumber,
    );
    final explicitWalletPhone = _resolveExplicitWalletPhone(parseResult);
    if (explicitWalletPhone != null) {
      if (explicitWalletPhone == normalizedTargetPhoneNumber) {
        return _WalletMention.target;
      }

      if (!targetMentioned) {
        return _WalletMention.other;
      }
    }

    final mentionedWalletPhoneNumbers = parseResult.mentionedPhoneNumbers
        .where(normalizedProviderPhoneNumbers.contains)
        .toSet();

    if (mentionedWalletPhoneNumbers.isEmpty) {
      return _WalletMention.ambiguous;
    }

    if (mentionedWalletPhoneNumbers.length == 1 &&
        mentionedWalletPhoneNumbers.first == normalizedTargetPhoneNumber) {
      return _WalletMention.target;
    }

    return _WalletMention.other;
  }

  static String? _resolveExplicitWalletPhone(SmsParseResult parseResult) {
    final counterparty = EgyptianPhoneNumber.tryNormalizeMobile(
      parseResult.counterpartyNumber,
    );
    final nonCounterpartyMentions = parseResult.mentionedPhoneNumbers
        .where((number) => number != counterparty)
        .toSet();

    if (nonCounterpartyMentions.length != 1) {
      return null;
    }

    return nonCounterpartyMentions.first;
  }

  static bool _chainsWithNearestAttributedRecords({
    required int index,
    required Set<int> attributedIndexes,
    required List<ParsedInboxSmsRecord> records,
  }) {
    final candidateIndexes = <int>{};

    for (final neighborIndex in attributedIndexes) {
      if (neighborIndex < index) {
        final current = candidateIndexes
            .where((candidate) => candidate < index)
            .fold<int?>(null, (best, candidate) {
              if (best == null || candidate > best) {
                return candidate;
              }
              return best;
            });
        if (current == null || neighborIndex > current) {
          if (current != null) {
            candidateIndexes.remove(current);
          }
          candidateIndexes.add(neighborIndex);
        }
      }

      if (neighborIndex > index) {
        final current = candidateIndexes
            .where((candidate) => candidate > index)
            .fold<int?>(null, (best, candidate) {
              if (best == null || candidate < best) {
                return candidate;
              }
              return best;
            });
        if (current == null || neighborIndex < current) {
          if (current != null) {
            candidateIndexes.remove(current);
          }
          candidateIndexes.add(neighborIndex);
        }
      }
    }

    for (final neighborIndex in candidateIndexes) {
      if (_balancesChain(
        left: records[index].parseResult,
        right: records[neighborIndex].parseResult,
      )) {
        return true;
      }
    }
    return false;
  }

  static const double _historyBalanceToleranceEgp = 50.0;

  static bool _balancesChain({
    required SmsParseResult left,
    required SmsParseResult right,
  }) {
    if (left.createdAt.isAfter(right.createdAt)) {
      return _balancesChain(left: right, right: left);
    }

    final olderBalance = left.balance;
    final newerBalance = right.balance;
    if (olderBalance == null || newerBalance == null) {
      return false;
    }

    final expectedNewerBalance = right.type == TransactionType.receive
        ? olderBalance + right.amount
        : olderBalance - right.amount;
    final difference = (newerBalance - expectedNewerBalance).abs();
    return difference <= _historyBalanceToleranceEgp;
  }

  // ── Backward balance-walk seeding ──────────────────────────────────────────

  static void _seedFromKnownWalletBalances({
    required List<ParsedInboxSmsRecord> records,
    required List<_WalletMention> mentions,
    required String normalizedTargetPhoneNumber,
    required Map<String, double> normalizedKnownWalletBalances,
    required Set<int> targetIndexes,
    required Set<int> otherIndexes,
  }) {
    final runningKnownBalances = Map<String, double>.from(
      normalizedKnownWalletBalances,
    );
    double? targetRunningBalance;

    for (var i = records.length - 1; i >= 0; i--) {
      // Anchor target running balance from definitively resolved target records.
      if (targetIndexes.contains(i)) {
        final b = records[i].parseResult.balance;
        if (b != null) {
          targetRunningBalance = _computePriorBalance(
            b,
            records[i].parseResult,
          );
        }
        continue;
      }

      if (otherIndexes.contains(i)) continue;
      if (mentions[i] != _WalletMention.ambiguous) continue;

      final result = records[i].parseResult;
      final balance = result.balance;
      if (balance == null) continue;

      final priorBalance = _computePriorBalance(balance, result);

      String? bestKnownPhone;
      var bestKnownDiff = _historyBalanceToleranceEgp + 1.0;
      for (final entry in runningKnownBalances.entries) {
        final diff = (entry.value - balance).abs();
        if (diff < bestKnownDiff) {
          bestKnownDiff = diff;
          bestKnownPhone = entry.key;
        }
      }

      final targetDiff = targetRunningBalance != null
          ? (targetRunningBalance - balance).abs()
          : double.infinity;

      final knownMatchExists =
          bestKnownPhone != null &&
          bestKnownDiff <= _historyBalanceToleranceEgp;

      if (knownMatchExists && bestKnownDiff <= targetDiff) {
        otherIndexes.add(i);
        runningKnownBalances[bestKnownPhone] = priorBalance;
      } else if (targetRunningBalance != null &&
          targetDiff <= _historyBalanceToleranceEgp &&
          targetDiff < bestKnownDiff) {
        targetIndexes.add(i);
        targetRunningBalance = priorBalance;
      } else if (!knownMatchExists) {
        targetIndexes.add(i);
        targetRunningBalance = priorBalance;
      }
    }
  }

  static double _computePriorBalance(
    double balanceAfter,
    SmsParseResult result,
  ) =>
      result.type == TransactionType.receive
          ? balanceAfter - result.amount
          : balanceAfter + result.amount;
}

enum _WalletMention { target, other, ambiguous }

final class _HistoryResolution {
  const _HistoryResolution({required this.targetRecords});

  final List<ParsedInboxSmsRecord> targetRecords;
}
