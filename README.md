# MerchantOS

A multi-tenant e-commerce SaaS — merchants sign up, open a store, and manage
products, inventory and orders; shoppers browse a public storefront, search, and
check out. Think of it as a lightweight Shopify.

**Live demo**

| | |
|---|---|
| Overview | https://srichsun.github.io/merchant_os/ |
| Storefront | https://merchant-os.onrender.com/s/demo-store |
| Admin | https://merchant-os.onrender.com (`owner@example.com` / `password123`) |

> Hosted on Render's free tier — the first request may take ~30s to wake up.

## Features

- **Multi-tenant** stores, isolated at the row level (`acts_as_tenant`).
- **Inventory with oversell protection** — checkout decrements stock under a
  pessimistic lock, covered by a threaded race-condition spec.
- **Order state machine** (AASM): `pending → paid → shipped`.
- **Background job chain** on payment — notify the store, email the buyer, queue
  fulfillment.
- **Checkout with a choice of gateway** — Stripe or ECPay (綠界). Both are hosted
  redirect flows confirmed by a signature-verified webhook; the buyer picks at
  checkout.
- **Transactional email** via Resend's HTTP API (order confirmation to the buyer).
- **Product images** on Tigris (S3-compatible) object storage via Active Storage,
  with Russian-doll fragment caching on the storefront.
- **Product search** with Postgres trigram (`pg_search`), no Elasticsearch.
- **Real-time order dashboard** — paid orders stream in over Turbo Streams +
  Action Cable.
- **JSON REST API** (`/api/v1`) with JWT auth and rack-attack rate limiting.
- **Observability**: Sentry error tracking + Lograge single-line JSON logs.

## Architecture highlights

- **Two ways to resolve the tenant** — the admin uses the logged-in user; the
  public storefront uses the store slug in the URL (`/s/:slug`).
- **Pluggable payments** — create a pending order → redirect to the chosen gateway
  (Stripe Checkout or ECPay) → the gateway calls a webhook → verify the signature
  (Stripe's signature / ECPay's `CheckMacValue`) → `order.pay!`. The browser
  redirect is never trusted; only the verified webhook marks an order paid.
- **Postgres-native infrastructure** — Solid Cache and Solid Cable keep the cache
  and Action Cable in Postgres, so the free tier runs with no Redis.
- **Frontend** — Hotwire for the admin and storefront (server-rendered HTML); a
  single stack, no separate SPA.

## Tech decisions

| Area | Choice | Why not the alternative |
|------|--------|-------------------------|
| Multi-tenancy | `acts_as_tenant` (row-level) | Apartment schema-per-tenant needs a migration per schema as stores grow |
| Search | `pg_search` trigram | No need to run an Elasticsearch cluster at this scale |
| Orders | AASM state machine | Explicit, testable states beat a hand-rolled `enum + if` |
| Oversell | Pessimistic lock | Most reliable under high contention; optimistic lock retries a lot |
| Payments | Stripe + ECPay, pluggable | One order/webhook flow behind both; the buyer chooses at checkout |
| Email | Resend HTTP API | Outbound SMTP is blocked on the host (connections time out) |
| Images | Active Storage + Tigris (S3) | The host has no object storage and an ephemeral disk |
| Cache / real-time | Solid Cache + Solid Cable | DB-backed, so no Redis on the free tier |
| Background jobs | `:async` (Sidekiq-ready) | Free tier has no Redis/worker; swap to Sidekiq when available |

## Tech stack

Rails 8 · PostgreSQL · Hotwire · Devise · Pundit · acts_as_tenant · AASM ·
pg_search · Stripe · ECPay · Resend · Active Storage + Tigris · Solid Cache/Cable ·
JWT · Sentry + Lograge · RSpec · Docker · GitHub Actions · Render

## Engineering

- **Tests**: RSpec + FactoryBot; every feature ships with specs, including a
  threaded oversell race-condition test.
- **CI** (GitHub Actions): RuboCop, RSpec, Brakeman, bundler-audit, gitleaks,
  Docker build.
- **Observability**: Sentry + Lograge with `request_id` / `tenant_id` / `user_id`
  on every log line.

## Running locally

Requires Ruby 3.4.x and PostgreSQL.

```bash
bundle install
bin/rails db:prepare   # create the database and load the schema
bin/rails db:seed      # demo data: two stores with products and orders
bin/dev                # Rails + Tailwind, then open http://localhost:3000
```

Run the test suite:

```bash
bin/rspec
```

Seeded logins (password `password123`): `owner@example.com`, `staff@example.com`
(Demo Store), `owner2@example.com` (Coffee Lab).

## Deployment

Deployed on Render from `render.yaml` (Docker web service + managed Postgres).
The database seeds itself on boot, so the demo always has data. Set
`RAILS_MASTER_KEY` in the host; payment, email and storage credentials are
environment variables (ECPay falls back to its public test credentials).
