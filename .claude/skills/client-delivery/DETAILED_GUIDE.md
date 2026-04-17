# Client Delivery — Detailed Guide

## client.json Field Reference

### Required Fields
| Field | Purpose | Example |
|-------|---------|---------|
| `CLIENT_NAME` | Full business display name | `"Acme Studio"` |
| `CLIENT_SLUG` | URL-safe ID (hyphens, no spaces) | `"acme-studio"` |
| `SUPABASE_URL` | Project URL from Supabase Settings → API | `"https://xyz.supabase.co"` |
| `SUPABASE_ANON_KEY` | Public JWT key from Supabase Settings → API | `"eyJhbGci..."` |

### Branding & UI
| Field | Purpose | Example | Notes |
|-------|---------|---------|-------|
| `PERSONALITY` | Visual language preset | `"luxury"` | luxury, minimal, bold, warm, corporate |
| `HERO_VARIANT` | Home hero layout | `"fullbleed"` | fullbleed, split, centered |
| `NAV_STYLE` | Navigation style | `"overlay"` | overlay, standard |
| `HOME_SECTIONS` | Sections shown on home page | `"hero,services,team,cta"` | comma-separated |
| `COLOR_PRIMARY` | Main brand color (no #) | `"C9A96E"` | |
| `COLOR_SECONDARY` | Secondary color | `"1A1A2E"` | |
| `COLOR_ACCENT` | Accent/highlight | `"E8D5B0"` | |
| `COLOR_SURFACE` | Splash/native background | `"0D0D0D"` | defaults to "000000" |
| `COLOR_ON_SURFACE` | Text on surface | `"F5F0E8"` | |
| `COLOR_ERROR` | Error state | `"CF6679"` | |
| `FONT_PRIMARY` | Headline typeface | `"Cormorant Garamond"` | Google Fonts name |
| `FONT_SECONDARY` | UI typeface | `"Inter"` | |

### Personality System
Each personality is a full visual language — not a color swap:
- **luxury** — Cormorant Garamond, generous whitespace, gold accents, minimal borders
- **minimal** — Inter, tight grid, monochrome, sharp edges
- **bold** — heavy typography, high contrast, strong CTAs
- **warm** — rounded corners, earthy palette, approachable layout
- **corporate** — structured nav, neutral palette, formal hierarchy

### Modules
Set in `MODULES` as a comma-separated string. Always include `home,contact,auth`.

| Module | Description | Requires |
|--------|-------------|---------|
| `home` | Landing page | Always on |
| `contact` | Contact form + send-contact Edge Fn | Always on |
| `auth` | Login/signup/profile | Always on |
| `booking` | Full 6-step booking flow | STRIPE_PK if taking payments |
| `newsletter` | Email subscription + welcome email | RESEND_KEY |
| `blog` | Admin-managed blog with SEO slugs | — |
| `gallery` | Photo gallery with lightbox | Supabase Storage "gallery" bucket |
| `testimonials` | Client reviews | — |
| `faq` | FAQ with admin editor | — |
| `subscriptions` | Recurring payment plans | STRIPE_PK + STRIPE_SK |
| `shop` | Product catalogue + Stripe checkout | STRIPE_PK + STRIPE_SK |
| `events` | Event listings + booking | STRIPE_PK |
| `courses` | Video course delivery | STRIPE_PK |
| `crm` | Admin CRM clients tab | Admin only — no nav entry for clients |
| `gdpr` | Cookie consent banner + forget-me | RESEND_KEY |
| `referrals` | Referral code system | booking |
| `intake` | Custom intake forms post-booking | booking |
| `gift` | Gift vouchers | STRIPE_PK |
| `loyalty` | Points + redemption | booking |
| `waitlist` | Waitlist when fully booked | booking |
| `packages` | Service bundles | booking |
| `reviews` | Public reviews + moderation | — |
| `recurring` | Subscription bookings | STRIPE_PK |

### Payments
| Field | Value | Notes |
|-------|-------|-------|
| `STRIPE_MODE` | `"standard"` | Solo operator, direct charges |
| `STRIPE_MODE` | `"connect_multi_staff"` | Express accounts, staff payouts |
| `STRIPE_PK` | `"pk_test_..."` or `"pk_live_..."` | Public key — in client.json |
| `STRIPE_SK` | `"sk_live_..."` | Secret key — pushed to Supabase secrets only, never committed |

### Feature Flags (boolean strings)
```
SMS_ENABLED, INTAKE_ENABLED, LOYALTY_ENABLED, GIFT_ENABLED, WAITLIST_ENABLED,
PACKAGES_ENABLED, REVIEWS_ENABLED, CLIENT_PHOTOS_ENABLED, RECURRING_ENABLED,
DIGEST_ENABLED, CHATBOT_ENABLED, PUSH_ENABLED, FCM_ENABLED,
GOOGLE_AUTH_ENABLED, APPLE_AUTH_ENABLED, GDPR_ENABLED, STRIPE_INVOICING_ENABLED
```
All default to `"false"`. Set to `"true"` to enable.

### SEO & Local Business
| Field | Purpose |
|-------|---------|
| `SEO_TITLE` | Page `<title>` tag (max 60 chars) |
| `SEO_DESCRIPTION` | Meta description (max 160 chars) |
| `OG_IMAGE` | Social preview image URL |
| `PHONE` | Schema.org format: `"+12125551234"` |
| `STREET`, `CITY`, `STATE`, `ZIP`, `COUNTRY` | LocalBusiness JSON-LD |
| `HOURS_JSON` | OpeningHoursSpecification array |

### Mobile
| Field | Purpose |
|-------|---------|
| `SHORT_NAME` | App name on home screen (max 12 chars) |
| `BUNDLE_ID` | Android/iOS identifier: `"com.acmestudio.app"` |
| `APPLE_TEAM_ID` | 10-char Apple Developer Team ID |

### Integrations
| Field | Purpose |
|-------|---------|
| `RESEND_KEY` | Transactional email API key |
| `FROM_EMAIL` | Verified sender address |
| `ANTHROPIC_API_KEY` | AI chatbot (Claude API) |
| `TIMEZONE` | Scheduling timezone: `"America/New_York"` |
| `SITE_URL` | Production URL (no trailing slash) — affects Stripe redirects + sitemap |
| `GOOGLE_PLACES_ID` | For Google Reviews auto-sync |

### Raspucat Integration (internal)
| Field | Purpose |
|-------|---------|
| `RASPUCAT_QUOTE_ID` | Quote UUID from Raspucat admin panel |
| `RASPUCAT_API` | Raspucat backend URL |
| `RASPUCAT_ADMIN_TOKEN` | Auth token for status callbacks |

---

## deliver.sh Step-by-Step

```bash
cd execution/frontend/app
./deliver.sh
```

| Step | What happens |
|------|-------------|
| **1** | Tool check — flutter, supabase, python3 must be on PATH |
| **2** | Validate client.json — required fields present; auto-patches pubspec.yaml name |
| **3** | `setup.sh` — runs DB migrations + seeds business_config + business_hours |
| **4** | Deploy Edge Functions + push secrets to Supabase |
| **5** | `prepare.sh` — processes .tpl files → web assets; generates sitemap.xml |
| **6** | `build.sh` — runs `flutter build web` |
| **Post** | Reports delivery status to Raspucat admin (if credentials set) |

**Prerequisite before first run:**
```bash
supabase link --project-ref <your-project-ref>
```

**Common warnings (non-fatal):**
- `STRIPE_PK empty` — payments disabled; booking flow skips payment step
- `RESEND_KEY not set` — emails won't send; booking still works
- `SITE_URL not set` — Stripe redirects fall back to localhost

**Manual checklist printed at end:**
1. Register JWT hook in Supabase Auth → Hooks
2. Set Auth redirect URL in Supabase Auth → URL Configuration
3. Customize email templates in Supabase Auth → Email Templates
4. Schedule crons in Supabase dashboard:
   - `send-reminders`: `0 10 * * *`
   - `send-review-requests`: `0 12 * * *`
   - `expire-pending-bookings`: `*/30 * * * *`
   - `send-abandoned-recovery`: `0 */2 * * *`
5. Deploy `build/web/` to hosting (Netlify, Vercel, etc.)
6. Set `STRIPE_SK` as Supabase secret if payments enabled
7. Register Stripe webhook (or use `--register-webhooks` flag)

---

## add-module.sh

```bash
cd execution/frontend/app
./add-module.sh newsletter
```

**What it does:**
1. Validates module ID against known list
2. Checks module isn't already in MODULES (idempotent)
3. Appends module to client.json MODULES
4. Runs `./deliver.sh --skip-build` (DB + functions, no Flutter rebuild)
5. Reports to Raspucat admin as "in_progress"
6. Reverts client.json automatically if deliver.sh fails

**After running:** rebuild Flutter and redeploy — `./deliver.sh --skip-db --skip-functions` (build only).

---

## prepare_mobile.sh

```bash
./deliver.sh --mobile
# or standalone:
./prepare_mobile.sh
```

**What it configures:**
- AndroidManifest.xml — domain + app label
- Runner.entitlements (iOS) — Universal Links domain
- pubspec.yaml — splash screen colors from COLOR_SURFACE
- web/.well-known/assetlinks.json — Android App Links (needs SHA-256 from keystore)
- web/.well-known/apple-app-site-association — iOS Universal Links (needs APPLE_TEAM_ID)
- Runs `flutter_native_splash` and `flutter_launcher_icons` if assets present

**Assets required:**
- `assets/images/splash_logo.png` — splash screen logo
- `assets/icons/app_icon.png` — 1024×1024, no alpha channel (iOS requirement)

---

## Common Failure Modes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `supabase: command not found` | CLI not installed | `brew install supabase/tap/supabase` |
| `Error: project not linked` | Missing `supabase link` | `supabase link --project-ref <ref>` |
| `STRIPE_PK is empty` warning | client.json missing key | Add key or accept no-payments mode |
| Sitemap missing blog posts | Supabase not reachable during prepare.sh | Non-fatal; re-run `prepare.sh` after DB is up |
| Edge function deploy fails | Supabase project not linked or wrong region | Check `supabase status` |
| `add-module.sh` reverts changes | `deliver.sh --skip-build` failed | Check migration file for the module; run `supabase db reset` locally |
