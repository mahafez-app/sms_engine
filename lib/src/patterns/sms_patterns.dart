class SmsPatterns {
  SmsPatterns._();

  // ─── Arabic ───────────────────────────────────────────────────────────────

  /// تم استلام مبلغ 3000 جنيه من رقم ...
  /// Flexible: handles multi-line, inverted names, and optional "تم" prefix.
  static final arReceiveFromNumber = RegExp(
    r'(?:تم\s+)?(?:[اأإ]ستلام|[اأإ]يداع|[اأإ]ستلمت)\s*(?:مبلغ)?\s*([\d,\.]+)\s*(?:جنيه|ج\.م|جم|جم\s+من)?.*?(?:من\s+رقم|من|ب[اإ]سم).*?(\+?[\d]{8,15})',
    dotAll: true,
  );

  /// تم تحويل 4500 جنيه لرقم 01120892874
  static final arSendToNumber = RegExp(
    r'(?:تم\s+)?(?:تحويل|[اأإ]رسال|حولت)\s*([\d,\.]+)\s*(?:جنيه|ج\.م|جم|جم\s+[اأإ]لى)?.*?(?:لرقم|[اأإ]لى\s+رقم|لحساب(?:\s+رقم)?)\s*[:\-]?\s*(\+?[\d]{8,15})',
    dotAll: true,
  );

  static final arBankReceive = RegExp(
    r'لحسابكم.*?بمبلغ.*?([\d,\.]+)',
    dotAll: true,
  );
  static final arBankSend = RegExp(
    r'من\s+حسابكم.*?بمبلغ.*?([\d,\.]+)',
    dotAll: true,
  );

  // ─── English ──────────────────────────────────────────────────────────────

  /// Received EGP1,000 from 00201140932674 ...
  /// Max 15 digits to cover 14-digit international numbers (002xxxxxxxxxx).
  static final enReceiveFromNumber = RegExp(
    r'[Rr]eceived\s+EGP\s*([\d,\.]+)\s+from\s+(\+?[\d]{8,15})',
    dotAll: true,
  );

  /// Sent EGP500 to 01012345678
  static final enSendToNumber = RegExp(
    r'(?:[Yy]ou\s+)?[Ss]ent\s+EGP\s*([\d,\.]+)\s+to\s+(\+?[\d]{8,15})',
    dotAll: true,
  );

  /// Transfer of EGP 500.00 sent to 01012345678
  static final enTransferSentToNumber = RegExp(
    r'[Tt]ransfer\s+of\s+EGP\s*([\d,\.]+)\s+sent\s+to\s+(\+?[\d]{8,15})',
    dotAll: true,
  );

  /// Transfer of EGP 500.00 received from 01012345678
  static final enTransferReceivedFromNumber = RegExp(
    r'[Tt]ransfer\s+of\s+EGP\s*([\d,\.]+)\s+received\s+from\s+(\+?[\d]{8,15})',
    dotAll: true,
  );

  // ─── Reference numbers ────────────────────────────────────────────────────

  /// رقم العملية: 018959810019
  static final refOperationAr = RegExp(r'رقم\s+العملية\s*[:\-]?\s*[\.]?(\d+)');

  /// كود العملية 018959810019
  static final refCodeAr = RegExp(r'كود\s+العملية\s*[:\-]?\s*[\.]?(\d+)');

  /// رقم المرجع 018959810019
  static final refNumberAr = RegExp(r'رقم\s+المرجع\s*[:\-]?\s*[\.]?(\d+)');

  /// رقم مرجعي 643111494336 — strict prefix required, no optional match.
  static final refBankAr = RegExp(r'رقم\s+مرجعي\s*[:\-]?\s*(\d{8,16})');

  /// Ref: 018959810019 — simplified: grab digits directly after Ref label.
  static final refEn = RegExp(r'Ref(?:\s*No\.?)?\s*[:\-]?\s*(\d{8,16})');

  /// 643111494336 يوم 08-04 — captures reference number appearing before "يوم"
  static final refBeforeDateAr = RegExp(r'(\d{8,16})\s+يوم');

  // ─── Balance ─────────────────────────────────────────────────────────────

  /// Available Balance: 10409.72
  static final balanceEn = RegExp(
    r'[Aa]vailable\s+[Bb]alance\s*[:\-]?\s*\.?([\d,\.]+)',
  );

  /// رصيدك الحالي: 9409.72 جنيه
  /// رصيد حسابك فى فودافون كاش الحالي 2126.69
  /// Uses [\d,]+(?:\.\d+)? to greedily capture integer-or-decimal without
  /// swallowing a trailing sentence period.
  static final balanceAr = RegExp(
    r'(?:رصيد\s+حسابك.*?الحالي|رصيدك\s+الحالي)\s*[:\-]?\s*\.?([\d,]+(?:\.\d+)?)',
    dotAll: true,
  );

  // ─── Datetime ─────────────────────────────────────────────────────────────

  /// 2026-04-14
  static final dateIso = RegExp(r'(\d{4})[\-\/](\d{1,2})[\-\/](\d{1,2})');

  /// Matches DD-MM-YYYY, DD-MM-YY, and YY-MM-DD.
  /// Disambiguated in logic using nearest-year heuristic.
  static final dateShort = RegExp(
    r'(\d{1,2})[\-\/](\d{1,2})[\-\/](\d{2,4})',
  );

  /// Apr 14, 2026
  static final dateEnglish = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{4})',
    caseSensitive: false,
  );

  /// 13:45 or 13:45:00 or 4:55:41 PM
  static final timePattern = RegExp(
    r'(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?\s*(AM|PM)?',
    caseSensitive: false,
  );
}
