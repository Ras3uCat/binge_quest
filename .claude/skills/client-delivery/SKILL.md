# Skill: Client Delivery Pipeline

## What This Skill Covers
The full lifecycle of delivering a Raspucat client app — from cloning the template to
a live, deployed site. This project's core differentiator: one `client.json` config file
+ one `deliver.sh` command produces an isolated, fully-branded Flutter app with its own
Supabase backend.

## Key Files
- `execution/frontend/app/client.json` — single source of truth for all client config
- `execution/frontend/app/deliver.sh` — orchestrates the full delivery pipeline
- `execution/frontend/app/prepare.sh` — processes web templates + generates sitemap
- `execution/frontend/app/prepare_mobile.sh` — configures native iOS/Android files
- `execution/frontend/app/add-module.sh` — adds a feature module to an existing client
- `planning/client/` — 19-section delivery guide

## Pipeline Overview

```
New client project
      │
      ▼
cp -r modular_project → clients/slug     Phase 0.5 — clone template
      │
      ▼
Fill client.json                          Phase 2 — config
      │
      ▼
./deliver.sh                              Phase 3–6 — full delivery
  ├── setup.sh (DB migrations + seed)
  ├── Deploy Edge Functions + secrets
  ├── prepare.sh (web templates + sitemap)
  └── build.sh (flutter build web)
      │
      ▼
Manual steps (JWT hook, crons, hosting)   Phase 7+ — post-delivery
      │
      ▼
./add-module.sh <id>                      Anytime — add feature modules
```

## Delivery Modes
- `./deliver.sh` — full delivery (DB + functions + build)
- `./deliver.sh --skip-db` — skip migrations (re-deploy functions only)
- `./deliver.sh --skip-build` — DB + functions, no Flutter build
- `./deliver.sh --mobile` — also configure iOS/Android native files
- `./deliver.sh --register-webhooks` — auto-register Stripe webhook
- `./deliver.sh --dry-run` — validate + print plan, no changes

## Module System
Modules are comma-separated in `client.json` MODULES field. The ModuleRegistry
builds nav + routes dynamically at runtime. Use `./add-module.sh <id>` to add
a module to a live client without re-delivering from scratch.

## When to Load DETAILED_GUIDE.md
- Troubleshooting a deliver.sh failure
- Filling in client.json for a new client
- Deciding which modules to enable
- Setting up mobile delivery
- Using add-module.sh on an existing client
