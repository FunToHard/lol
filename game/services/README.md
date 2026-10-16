# Platform Services & Adapters (`game/services`)

## Responsibility
Decouples external platform SDKs (Ads, In-App Purchases, Analytics, Game Services) from gameplay code through abstract interface contracts.

## Boundary Rules
- **MUST OWN:** Abstract service contracts (`ads_service.lua`, `iap_service.lua`), mock adapters for development, and native production adapters (`extension-admob`, `extension-iap`).
- **MUST NOT OWN:** Board rules, economy calculations, or gameplay state.
- **Fail-Open Policy:** If an ad or store service is unreachable or offline, the adapter fails gracefully without stalling gameplay.
