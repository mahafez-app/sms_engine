import 'dart:developer';

import 'package:mahafez_core/mahafez_core.dart';
import '../models/sms_wallet_candidate.dart';
import '../models/sms_wallet_match_result.dart';

/// Selects the correct wallet from a list of same-provider candidates.
///
/// Resolution priority:
///   0. Derived wallet phone guard    — when the SMS mentions exactly 2 phone
///      numbers and one is the counterparty, the other is provably the wallet's
///      own number. If that number matches no candidate, returns
///      [SmsWalletDefiniteMiss]. If it matches one candidate exactly, returns
///      that wallet immediately.
///   1. Single wallet                 — trivial case.
///   2. Explicit wallet phone mention — matches the wallet number when the
///      provider includes it in the SMS body.
///   3. Balance-delta correlation     — uses parsed SMS balance to identify
///      which wallet's running total matches after the transaction.
///
/// Balance-delta tolerance is ±[_maxBalanceDeltaToleranceEgp] EGP to absorb transfer taxes
/// (Egyptian providers charge up to 10 EGP per transaction).
class SmsWalletMatcher {
  SmsWalletMatcher._();

  static const _tag = 'SmsWalletMatcher';
  static const _maxBalanceDeltaToleranceEgp = 50.0;

  static SmsWalletMatchResult<T> resolve<T extends SmsWalletCandidate>({
    required List<T> wallets,
    required SmsWalletMatchInput input,
  }) {
    if (wallets.isEmpty) return const SmsWalletNoCandidate();

    // Step 0 — Explicit wallet phone guard.
    final guardResult = _applyExplicitWalletPhoneGuard<T>(
      wallets: wallets,
      input: input,
    );
    if (guardResult != null) return guardResult;

    if (wallets.length == 1) {
      return SmsWalletMatchedResult<T>(wallets.first);
    }

    final phoneMatch = _matchByMentionedWalletPhone<T>(
      wallets: wallets,
      input: input,
    );
    if (phoneMatch != null) {
      log(
        'Explicit phone mention identified wallet ${phoneMatch.id}.',
        name: _tag,
      );
      return SmsWalletMatchedResult<T>(phoneMatch);
    }

    final balanceMatch = _matchByBalanceDelta<T>(wallets: wallets, input: input);
    if (balanceMatch != null) {
      log(
        'Balance-delta identified wallet ${balanceMatch.id} '
        '(balance ${balanceMatch.currentBalance} -> ${input.parsedBalance}).',
        name: _tag,
      );
      return SmsWalletMatchedResult<T>(balanceMatch);
    }

    log('No definitive wallet signal found.', name: _tag);
    return const SmsWalletNoCandidate();
  }

  static String? resolveExplicitWalletPhone(SmsWalletMatchInput input) {
    return _resolveExplicitWalletPhone(input);
  }

  // ── Step 0 — Explicit wallet phone guard ─────────────────────────────────

  static SmsWalletMatchResult<T>? _applyExplicitWalletPhoneGuard<
    T extends SmsWalletCandidate
  >({required List<T> wallets, required SmsWalletMatchInput input}) {
    final explicitWalletPhone = _resolveExplicitWalletPhone(input);
    if (explicitWalletPhone == null) return null;

    final matching = wallets.where((w) {
      final normalized = EgyptianPhoneNumber.tryNormalizeMobile(w.phoneNumber);
      return normalized == explicitWalletPhone;
    }).toList();

    if (matching.isEmpty) {
      log(
        'Explicit wallet phone $explicitWalletPhone matches no registered '
        'wallet — discarding SMS.',
        name: _tag,
      );
      return const SmsWalletDefiniteMiss();
    }

    if (matching.length == 1) {
      log(
        'Explicit wallet phone $explicitWalletPhone uniquely matched wallet '
        '${matching.first.id}.',
        name: _tag,
      );
      return SmsWalletMatchedResult<T>(matching.first);
    }

    final mentionedWalletMatches = wallets.where((wallet) {
      final normalized = EgyptianPhoneNumber.tryNormalizeMobile(
        wallet.phoneNumber,
      );
      return normalized != null &&
          input.mentionedPhoneNumbers.contains(normalized);
    }).toList();

    if (mentionedWalletMatches.length == 1) {
      log(
        'Explicit wallet-phone derivation fell back to directly mentioned wallet '
        '${mentionedWalletMatches.first.id}.',
        name: _tag,
      );
      return SmsWalletMatchedResult<T>(mentionedWalletMatches.first);
    }

    // Multiple candidates share the same phone — unusual, fall through.
    log(
      'Explicit wallet phone $explicitWalletPhone matched ${matching.length} '
      'wallets — continuing cascade.',
      name: _tag,
    );
    return null;
  }

  static String? _resolveExplicitWalletPhone(SmsWalletMatchInput input) {
    final counterparty = EgyptianPhoneNumber.tryNormalizeMobile(
      input.counterpartyNumber,
    );
    final nonCounterpartyMentions = input.mentionedPhoneNumbers
        .where((number) => number != counterparty)
        .toSet();

    return nonCounterpartyMentions.length == 1
        ? nonCounterpartyMentions.first
        : null;
  }

  // ── Step 2 — Explicit phone mention ─────────────────────────────────────────

  static T? _matchByMentionedWalletPhone<T extends SmsWalletCandidate>({
    required List<T> wallets,
    required SmsWalletMatchInput input,
  }) {
    if (input.mentionedPhoneNumbers.isEmpty) return null;

    final mentionedNumbers = input.mentionedPhoneNumbers.toSet();
    final counterpartyNumber = EgyptianPhoneNumber.tryNormalizeMobile(
      input.counterpartyNumber,
    );

    final matchedWallets = wallets.where((wallet) {
      final normalizedWalletPhone = EgyptianPhoneNumber.tryNormalizeMobile(
        wallet.phoneNumber,
      );
      return normalizedWalletPhone != null &&
          mentionedNumbers.contains(normalizedWalletPhone);
    }).toList();

    if (matchedWallets.isEmpty) return null;
    if (matchedWallets.length == 1) {
      final matchedWallet = matchedWallets.first;
      final normalizedWalletPhone = EgyptianPhoneNumber.tryNormalizeMobile(
        matchedWallet.phoneNumber,
      );
      if (normalizedWalletPhone == null) return null;

      final onlyCounterpartyMentioned =
          counterpartyNumber != null &&
          input.mentionedPhoneNumbers.length == 1 &&
          normalizedWalletPhone == counterpartyNumber;
      return onlyCounterpartyMentioned ? null : matchedWallet;
    }

    if (counterpartyNumber == null) return null;

    final nonCounterpartyWallets = matchedWallets.where((wallet) {
      final normalizedWalletPhone = EgyptianPhoneNumber.tryNormalizeMobile(
        wallet.phoneNumber,
      );
      return normalizedWalletPhone != counterpartyNumber;
    }).toList();

    return nonCounterpartyWallets.length == 1
        ? nonCounterpartyWallets.first
        : null;
  }

  // ── Step 3 — Balance-delta ───────────────────────────────────────────────────

  static T? _matchByBalanceDelta<T extends SmsWalletCandidate>({
    required List<T> wallets,
    required SmsWalletMatchInput input,
  }) {
    final parsedBalance = input.parsedBalance;
    final amount = input.amount;
    final type = input.transactionType;

    if (parsedBalance == null || amount == null || type == null) return null;

    final matches = <({T wallet, double difference})>[];

    for (final wallet in wallets) {
      final cached = wallet.currentBalance;

      // The expected local balance based purely on what the SMS reported
      final expectedCached = type == TransactionType.receive
          ? parsedBalance - amount
          : parsedBalance + amount;

      final difference = (cached - expectedCached).abs();
      matches.add((wallet: wallet, difference: difference));
    }

    if (matches.isEmpty) return null;

    // Sort by absolute nearest expected balance
    matches.sort((a, b) => a.difference.compareTo(b.difference));

    // If there is an exact tie in distance, we cannot safely decide via balance.
    if (matches.length > 1 && matches[0].difference == matches[1].difference) {
      return null;
    }

    if (matches.first.difference > _maxBalanceDeltaToleranceEgp) {
      return null;
    }

    return matches.first.wallet;
  }
}
