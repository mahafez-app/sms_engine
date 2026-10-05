# mahafez_sms_engine

Layer 2 Services / Capabilities Package for the Mahafez Platform.

A headless Egyptian wallet SMS listening and regex parsing engine with zero UI dependencies.

---

## Architecture Role

In the Mahafez 4-Layer Architecture ($L_4 \to L_3 \to L_2 \to L_1$):
* **Layer 2 (Capability / Service Layer):** Reusable business capabilities without UI widgets.
* **Pure Downward Dependencies:** Depends only on `mahafez_core` (Layer 1) and low-level telephony plugins.
* **Zero Cross-Product Dependencies:** Has zero knowledge of `wallet_product`, `transaction_product`, Firestore, or UI screens.

---

## Supported Providers

* **Vodafone Cash:** Arabic and English transfer/receive formats, reference numbers, balance extraction.
* **Orange Money / Orange Cash:** Standard Arabic/English formats, bank transfers, operation codes.
* **Etisalat Cash:** Standard transfer/receive formats, reference codes.
* **WE Pay:** Standard transfer/receive formats.
* **InstaPay / Bank Alerts:** NBE, CIB, Banque Misr, QNB, AAIB, HSBC, Fawry.

---

## Features

1. **Regex Parsing Engine:** Extracts amount, transaction type (`send` / `receive`), reference number, running balance, and counterparty phone numbers.
2. **Deterministic Matcher:**
   - Explicit wallet phone number resolution.
   - Disambiguation between multiple wallets on the same provider via phone mentions and running balance delta correlation.
3. **Historical Inbox Synchronization:**
   - Queries Android SMS inbox with multi-sender filters.
   - Backward balance-walk algorithm attributing ambiguous history records to registered wallets.
4. **Retry Queue Management:**
   - Persistent queue mechanism (`PendingSmsRetryService`) storing raw SMS records for offline/transient failure retries.
5. **Reactive Event Stream:**
   - `SmsEngineService` dispatches clean `SmsTransactionEvent` streams for host app consumers.
