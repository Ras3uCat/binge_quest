---
name: stripe-webhooks-and-access-control
description: Secure Stripe webhook handling, idempotency, event mapping to Supabase access flags for subscriptions.
when_to_use: Use when implementing webhook endpoints, processing Stripe events, or updating user access states like is_premium.
scope: execution/backend/payments/
authority: high
alwaysApply: true
---

# Stripe Webhooks & Access Control

## Non-Negotiable Rules
- **Signature Verification:** Verify `Stripe-Signature` header on ALL incoming webhooks.
- **Idempotency:** Use `evt_id` to prevent double-processing.
- **Environment:** `STRIPE_WEBHOOK_SECRET` from protected env vars only.
- **No Client Authority:** Backend controls `is_premium` via webhooks; Flutter reads from Supabase `profiles` table.

## Event Mapping
| Event | Action |
|-------|--------|
| `checkout.session.completed` | Provision initial access (set `is_premium: true`). |
| `customer.subscription.deleted` | Revoke access immediately (`is_premium: false`). |
| `invoice.payment_failed` | Trigger "payment required" UI state. |

## Security Checklist (Before Merge)
1. No Stripe secrets hardcoded or in logs.
2. Webhook endpoint public but signature-protected.
3. Handles unknown event types gracefully.
4. Test with `Stripe-Version: 2026-01-28.clover`.
