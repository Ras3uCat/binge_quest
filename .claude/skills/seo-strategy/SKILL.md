# SEO Strategy Skill
**Scope:** Flutter web client delivery platform — site-wide SEO + service page optimization.
**Source methodology:** Adapted from `/home/ryan/Documents/documents/development/seo-strategy/SKILL.md`

---

## Mode Detection

**Use Mode 1 (Service Page SEO)** when:
- User asks to optimize a specific service (e.g., "SEO this haircut service", "improve ranking for laser hair removal")
- User provides a service name, slug, or description to optimize
- User says "optimize this service", "make this service page rank", "improve service SEO"

**Use Mode 2 (Site-Wide SEO Strategy)** when:
- User asks for a full SEO audit, site-wide strategy, or keyword map
- User says "audit my site", "SEO strategy for this client", "full SEO review"
- User is onboarding a new client and wants to set up SEO from scratch

---

## Project SEO Architecture

### Where SEO data lives:

| Layer | File | What it controls |
|-------|------|-----------------|
| Global meta | `web/index.html.tpl` | Default `<title>`, `<meta description>`, OG tags, LocalBusiness JSON-LD |
| Client config | `client.json` | `SEO_TITLE`, `SEO_DESCRIPTION`, `OG_IMAGE`, `PHONE`, `STREET`, `CITY`, `STATE`, `ZIP`, `COUNTRY`, `SHORT_NAME` |
| Per-page meta | `lib/core/widgets/seo_wrapper.dart` | Injects `<title>`, `<meta description>`, `canonical`, `og:url`, JSON-LD per route |
| Web impl | `lib/core/widgets/seo_wrapper_web.dart` | DOM manipulation via `package:web` |
| Stub | `lib/core/widgets/seo_wrapper_stub.dart` | No-op for non-web builds |
| Service slugs | `lib/core/utils/slugify.dart` + `prepare.sh` | Character-by-character slug generation |
| Sitemap | `prepare.sh` | Auto-generates `sitemap.xml` from MODULES + published blog slugs |
| Service data | DB `services` table | `name`, `description`, `image_url` — rendered on `/services/[slug]` |

### SeoWrapper API:
```dart
SeoWrapper(
  title: 'Page Title | Business Name',      // injected as <title> and og:title
  description: 'Meta description ...',       // <meta name="description"> + og:description
  canonical: 'https://example.com/page',    // <link rel="canonical">
  jsonLd: '{ "@context": "...", ... }',     // injected <script type="application/ld+json">
  jsonLdId: 'service-slug',                 // deduplication key — prevents duplicate scripts on nav
  child: Scaffold(...),
)
```

### Files touched for service page SEO:
- `lib/modules/services/views/service_detail_view.dart` — SeoWrapper params
- `lib/modules/services/views/services_list_view.dart` — SeoWrapper params
- DB `services` table — `name`, `description`, `image_url`
- `prepare.sh` — sitemap includes `/services/[slug]` for all services

### Files touched for site-wide SEO:
- `client.json` — SEO_TITLE, SEO_DESCRIPTION, OG_IMAGE, address fields
- `web/index.html.tpl` — global title, LocalBusiness JSON-LD schema
- `lib/modules/home/views/` — SeoWrapper on home_view
- `lib/modules/blog/views/` — SeoWrapper on blog_post_view
- `prepare.sh` — sitemap, meta robots, canonical base URL

---

# MODE 1: Service Page SEO Optimization

## Step 0: Gather Context (MANDATORY)

Ask the user (one message, all questions):

1. **Service name & description** — "What is the exact service name and a brief description? Or paste the current DB description."
2. **Target keyword** — "What keyword should this service page rank for? (e.g., 'laser hair removal London') Or say 'suggest' and I'll research."
3. **Location** — "What city/region is this client based in? Local SEO modifiers matter."
4. **Price point** — "Approx price range? (helps with transactional intent copy)"
5. **Competitors** — "Any local competitors whose service pages you want to outrank? (optional)"

## Step 1: Keyword Research

Use `WebSearch` to find the top 5 organic results for the target keyword (+ location modifier).

For each top result use `WebFetch` to extract:
- Exact `<title>` and `<h1>`
- All `<h2>` / `<h3>` headings (reveals mandatory subtopics)
- Approximate word count
- Schema markup type used (Service, LocalBusiness, etc.)
- Unique selling points or trust signals in the copy

Build a **keyword map**:
- **Primary keyword** — confirmed with user
- **Secondary keywords** — long-tail variations from competitor titles/H2s
- **LSI keywords** — semantically related terms across 2+ competitors. Aim for 20–30 terms.
  Categories: process terms, pricing terms, trust/quality terms, pain-point terms, location terms.
- Use `WebSearch` for "[keyword] people also ask" to find additional LSI terms.

## Step 2: Gap Analysis

Compare against current service description:
- **Content gaps** — subtopics all top competitors cover that we're missing
- **LSI gaps** — semantic terms absent from current description
- **Intent match** — does our page satisfy transactional intent (book/hire) with a clear CTA?
- **Trust signals** — reviews, certifications, duration, experience claims

## Step 3: Write Optimized Service Content

Produce:

### 3a. Optimized Service Name
- Short, keyword-rich, natural (e.g., "Laser Hair Removal" not "Premium Advanced Laser Hair Service")
- Max 50 chars

### 3b. Optimized DB Description (for `services` table)
- 150–250 words
- Primary keyword in first sentence
- LSI keywords woven naturally throughout
- Covers: what it is, what's included, duration, who it's for, why choose this provider
- Ends with soft CTA (e.g., "Book your session today.")
- **This is what renders on the service detail page body**

### 3c. SeoWrapper `title` (60 chars max)
Format: `{Service Name} in {City} | {Business Name}`
Example: `Laser Hair Removal in London | Glow Studio`

### 3d. SeoWrapper `description` (150–160 chars)
- Primary keyword in first 20 words
- Value proposition + CTA
- Example: `Professional laser hair removal in London. Smooth results in 6 sessions. Book a free consultation at Glow Studio today.`

### 3e. SeoWrapper `canonical`
```dart
canonical: '${AppEnv.siteUrl}/services/${service.slug}',
```

### 3f. JSON-LD (Service schema)
```json
{
  "@context": "https://schema.org",
  "@type": "Service",
  "@id": "{{SITE_URL}}/services/{{SLUG}}",
  "name": "{{SERVICE_NAME}}",
  "description": "{{DESCRIPTION_FIRST_SENTENCE}}",
  "provider": {
    "@type": "LocalBusiness",
    "name": "{{BUSINESS_NAME}}",
    "url": "{{SITE_URL}}",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "{{STREET}}",
      "addressLocality": "{{CITY}}",
      "addressRegion": "{{STATE}}",
      "postalCode": "{{ZIP}}",
      "addressCountry": "{{COUNTRY}}"
    }
  },
  "areaServed": "{{CITY}}",
  "url": "{{SITE_URL}}/services/{{SLUG}}"
}
```

### 3g. Slug verification
Run `slugify(serviceName)` mentally — confirm the URL will be clean:
- All lowercase, hyphens only, no special chars
- Example: "Laser Hair Removal" → `laser-hair-removal`

## Step 4: Implementation

### DB update (service description):
```sql
UPDATE services
SET name = '{{NAME}}', description = '{{DESCRIPTION}}'
WHERE id = '{{ID}}';
```

### Flutter update (service_detail_view.dart):
```dart
SeoWrapper(
  title: '${service.name} in ${AppEnv.city} | ${AppEnv.clientName}',
  description: service.description.length > 160
      ? '${service.description.substring(0, 157)}...'
      : service.description,
  canonical: '${AppEnv.siteUrl}/services/${service.slug}',
  jsonLd: _buildServiceJsonLd(service),
  jsonLdId: 'service-${service.slug}',
  child: Scaffold(...),
)
```

Add `AppEnv.city` if not present (dart-define `CITY` from `client.json`).

### No sitemap change needed — `prepare.sh` auto-generates from DB.

---

# MODE 2: Site-Wide SEO Strategy

## Step 0: Gather Context (MANDATORY)

Ask the user (one message):

1. **Client business type** — "What type of business is this client? (e.g., hair salon, tattoo studio, physiotherapy clinic)"
2. **Location** — "City, region, and country?"
3. **Top 3–5 target keywords** — "What keywords should the whole site rank for? Or say 'analyze and suggest'."
4. **Primary competitor sites** — "Any competitor websites to benchmark against? (optional)"
5. **SEO goal** — "Primary goal: local visibility, organic traffic, specific service rankings, or all of the above?"
6. **LSI priorities** — "Any industry-specific terms to prioritize? Or say 'research for me'."

## Step 1: Site Inventory

Map all pages this Flutter site will have based on MODULES in `client.json`:

| Route | Page | Current SEO status |
|-------|------|--------------------|
| `/` | Home | SeoWrapper in `home_view.dart` |
| `/services` | Services list | SeoWrapper in `services_list_view.dart` |
| `/services/[slug]` | Each service | SeoWrapper in `service_detail_view.dart` |
| `/booking` | Booking flow | No public SEO (behind auth intent) |
| `/blog` | Blog list | SeoWrapper in `blog_list_view.dart` (if enabled) |
| `/blog/[slug]` | Blog post | SeoWrapper in `blog_post_view.dart` (if enabled) |
| `/events` | Events list | SeoWrapper in `events_list_view.dart` (if enabled) |
| `/events/[slug]` | Event detail | SeoWrapper in `event_detail_view.dart` (if enabled) |

## Step 2: Competitor Research

For each target keyword use `WebSearch` + `WebFetch` on top 3 results:
- Title, meta description, H1/H2 structure
- Schema markup types used
- Page structure and trust signals
- Local SEO signals (NAP consistency, Google Business mentions)

## Step 3: Keyword Map

Build a full keyword map across all pages:

| Page | Primary Keyword | Secondary Keywords | LSI Terms |
|------|-----------------|--------------------|-----------|
| Home | e.g. "hair salon London" | ... | ... |
| Services | "beauty services London" | ... | ... |
| [service-slug] | "[service] London" | ... | ... |
| Blog posts | topic-specific | ... | ... |

## Step 4: Global SEO Audit

Check and produce recommendations for:

### 4a. client.json SEO fields
```json
{
  "SEO_TITLE": "{Primary Keyword} | {Business Name}",
  "SEO_DESCRIPTION": "150-160 char meta for homepage. Keyword in first 20 words.",
  "OG_IMAGE": "Absolute URL to branded 1200×630 image",
  "SHORT_NAME": "Business Name (≤30 chars for PWA)",
  "CITY": "City name for local SEO",
  "STATE": "Region/county",
  "COUNTRY": "ISO 3166-1 alpha-2 (e.g. GB, US)",
  "STREET": "Street address",
  "ZIP": "Postal code",
  "PHONE": "+44xxxxxxxxxx"
}
```

### 4b. LocalBusiness JSON-LD (web/index.html.tpl)
Verify the template has a complete LocalBusiness schema:
```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "CLIENT_NAME",
  "url": "SITE_URL",
  "telephone": "PHONE",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "STREET",
    "addressLocality": "CITY",
    "addressRegion": "STATE",
    "postalCode": "ZIP",
    "addressCountry": "COUNTRY"
  },
  "openingHoursSpecification": [...]
}
```

### 4c. Per-page SeoWrapper audit
For each major page, verify:
- [ ] `title` — 50–60 chars, primary keyword near start
- [ ] `description` — 150–160 chars, keyword + CTA
- [ ] `canonical` — correct absolute URL
- [ ] `jsonLd` — appropriate schema type (Service, BlogPosting, Event, etc.)
- [ ] `jsonLdId` — unique per page type, prevents duplication

### 4d. Sitemap completeness (prepare.sh)
Verify these routes are in the generated sitemap:
- `/` (homepage) — `priority="1.0"`
- `/services` — `priority="0.8"`
- `/services/[each-slug]` — `priority="0.8"` (auto-generated from DB)
- `/blog/[each-slug]` — `priority="0.6"` (if blog enabled, auto from DB)
- `/events` + `/events/[slug]` — `priority="0.7"` (if events enabled)

Missing routes? Update `prepare.sh` sitemap generation block.

### 4e. Technical SEO checklist
- [ ] `robots.txt` — exists, not blocking `/services/` or `/blog/`
- [ ] `canonical` tags on all public pages (no duplicates from query params)
- [ ] HTML renderer used (Flutter web — confirm `--web-renderer html` in build command)
- [ ] Page titles unique per page (no two pages share same `<title>`)
- [ ] `hreflang` if multi-language (skip if single locale)
- [ ] Image alt text on hero images and service images (check `services_section.dart`)
- [ ] Google Search Console: submit sitemap after deploy

## Step 5: Deliverable

Produce a **SEO Strategy Document** covering:
1. Keyword map (all pages)
2. Recommended `client.json` SEO field values
3. Recommended SeoWrapper params per page (as code snippets)
4. `web/index.html.tpl` JSON-LD update (if needed)
5. Prioritized action list (Critical / High / Medium)
6. Blog content ideas targeting secondary keywords (if blog module enabled)

Format as markdown. Save to `planning/seo-strategy-{CLIENT_SLUG}.md`.

---

## AppEnv SEO Fields Reference

```dart
// Available via dart-define from client.json:
AppEnv.clientName     // CLIENT_NAME
AppEnv.siteUrl        // SITE_URL  (no trailing slash)
// Add these if not present:
AppEnv.city           // CITY
AppEnv.phone          // PHONE
```

To add a new AppEnv field:
1. Add to `client.json`: `"CITY": "London"`
2. Add to `lib/core/config/app_env.dart`:
   ```dart
   static const city = String.fromEnvironment('CITY', defaultValue: '');
   ```
3. Pass via `--dart-define-from-file=client.json` (already in build scripts)

---

## LSI Keyword Categories for Service Businesses

When researching LSI terms for beauty/wellness/health services:
- **Process terms**: treatment, session, appointment, consultation, aftercare, results
- **Trust terms**: certified, trained, experienced, professional, licensed, vetted
- **Pain-point terms**: permanent, painless, fast, effective, affordable, safe
- **Comparison terms**: vs waxing, alternatives, traditional vs laser
- **Local terms**: near me, {city}, {neighbourhood}, local, nearby
- **Booking terms**: book online, same-day, availability, pricing, packages

---

## Key Constraints (DO NOT VIOLATE)

- **Never** put SEO meta in StatefulWidget rebuild cycles — SeoWrapper is called once per route push
- **Never** use `window.document.title = ...` directly — always go through `SeoWrapper`
- **Never** hardcode business name/URL in JSON-LD — always use `AppEnv.clientName` / `AppEnv.siteUrl`
- **Never** duplicate `jsonLdId` across views — each schema injection needs a unique ID
- `seo_wrapper_web.dart` uses `package:web` (not `dart:html`) — do NOT revert to dart:html imports
