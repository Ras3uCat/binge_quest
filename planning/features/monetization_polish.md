# Feature: Phase 3 - Monetization & Polish

## Status
HOLD / DO NOT IMPLEMENT NOW

## Overview
Implement AdMob integration, a premium ad-free tier, and overall UI/UX polish.

## Acceptance Criteria
- [ ] AdMob banner and interstitial ads implemented
- [ ] Stripe/In-App Purchase for Premium tier
- [ ] Premium users see no ads
- [ ] Smooth animations and loading states (skeletons) throughout the app

## Backend Changes
- `users.is_premium` column and logic
- Stripe webhook integration for subscription management

## Frontend Changes
- `AdController` to manage ad display and frequency
- `PremiumController` to handle subscriptions and ad-free state
- UI: Ad banners on Dashboard and Watchlist
- UI: Premium upgrade screen
- UI: Skeleton loaders for all list views

## QA Checklist
- [ ] Verify ads are hidden for premium users
- [ ] Verify subscription status persists across sessions
- [ ] Verify ads do not overlap critical UI elements
