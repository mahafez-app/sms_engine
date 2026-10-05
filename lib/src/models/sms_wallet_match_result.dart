import 'package:mahafez_core/mahafez_core.dart';
import 'sms_wallet_candidate.dart';

/// Signals extracted from a parsed SMS, used to disambiguate between wallets
/// that share the same provider.
class SmsWalletMatchInput {
  const SmsWalletMatchInput({
    this.amount,
    this.transactionType,
    this.parsedBalance,
    this.counterpartyNumber,
    this.mentionedPhoneNumbers = const <String>[],
  });

  /// Amount parsed from the SMS body (e.g. 500.0).
  final double? amount;

  /// Whether this was a receive or send transaction.
  final TransactionType? transactionType;

  /// Post-transaction balance reported in the SMS body.
  /// Present in most Egyptian provider messages.
  final double? parsedBalance;

  /// Counterparty number parsed from the transaction body, if present.
  final String? counterpartyNumber;

  /// All normalized Egyptian mobile numbers mentioned anywhere in the SMS.
  final List<String> mentionedPhoneNumbers;
}

// ── Resolution result ─────────────────────────────────────────────────────────

/// Sealed result of wallet resolution.
///
/// Callers must handle all three variants:
/// - [SmsWalletMatchedResult]   — a wallet was confidently identified.
/// - [SmsWalletDefiniteMiss]    — the SMS structurally identifies a wallet
///   phone that does not match any known wallet; **discard silently**.
/// - [SmsWalletNoCandidate]     — resolution failed non-definitively;
///   the caller should enqueue for retry.
sealed class SmsWalletMatchResult<T extends SmsWalletCandidate> {
  const SmsWalletMatchResult();
}

final class SmsWalletMatchedResult<T extends SmsWalletCandidate>
    extends SmsWalletMatchResult<T> {
  const SmsWalletMatchedResult(this.wallet);
  final T wallet;
}

/// The SMS structurally implies a wallet phone number that does not exist
/// among the registered wallets. The transaction provably does not belong to
/// any known wallet — discard without retry.
final class SmsWalletDefiniteMiss<T extends SmsWalletCandidate>
    extends SmsWalletMatchResult<T> {
  const SmsWalletDefiniteMiss();
}

/// No confident match was found, but the miss is not definitive — could be a
/// transient state (wallets not yet loaded, balance stale, etc.).
/// Enqueue for retry.
final class SmsWalletNoCandidate<T extends SmsWalletCandidate>
    extends SmsWalletMatchResult<T> {
  const SmsWalletNoCandidate();
}
