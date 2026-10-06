# sms_engine

Layer 2 headless SMS parsing and telephony capability for Mahafez.

## Responsibility

The package parses supported Egyptian wallet/bank SMS formats and provides generic matching, inbox-history and retry primitives. It emits parsed records/events and does not own wallet persistence, transaction entities, Firebase repositories, product UI or app routing. `wallet_product` adapts these generic capabilities to wallet and transaction behavior.

## Layer boundary

The package depends on `mahafez_core` and platform/plugin libraries. It must remain independent of all Layer 3 products and Layer 4 apps. Telephony permission prompts and app lifecycle policy stay with the host/product integration.

## Use

```yaml
dependencies:
  sms_engine:
    git:
      url: https://github.com/mahafez-app/sms_engine.git
      ref: v1.0.1
```

See `lib/sms_engine.dart` for the public API and supported parser/event contracts.
