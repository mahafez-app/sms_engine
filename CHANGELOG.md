# Changelog

## 1.0.0

* Initial release of `mahafez_sms_engine` (Layer 2 Capability Package).
* Egyptian wallet regex parsers: Vodafone Cash, Orange Money, Etisalat Cash, WE Pay, InstaPay.
* Deterministic wallet disambiguation matcher with `SmsWalletCandidate` contract.
* Inbox historical transaction querying and backward balance-walk resolution.
* Offline retry queue service (`PendingSmsRetryService`).
* Reactive event stream service (`SmsEngineService`).
