# Payments Development (Financial Safety)
**Scope:** `execution/backend/payments/` | **Authority:** High

## Overview
Payments in Raspucat are handled via Stripe. Follow the granular skills below for specific implementation details.

## Granular Payment Skills
- **Subscription Flows:** [stripe-checkout-subscriptions](file:///home/ryan/Documents/development/flutter_apps/raspucat/.cloud/skills/stripe-checkout-subscriptions/SKILL.md)
- **Webhooks & Access:** [stripe-webhooks-and-access-control](file:///home/ryan/Documents/development/flutter_apps/raspucat/.cloud/skills/stripe-webhooks-and-access-control/SKILL.md)
- **API Management:** [stripe-api-versioning-and-upgrades](file:///home/ryan/Documents/development/flutter_apps/raspucat/.cloud/skills/stripe-api-versioning-and-upgrades/SKILL.md)

## Core Non-Negotiables
- **No Client Authority:** Flutter clients NEVER update their own premium state.
- **Webhook Source of Truth:** All access changes must derive from verified Stripe Webhooks.
- **Financial Safety:** Never hardcode secrets; always verify signatures.

