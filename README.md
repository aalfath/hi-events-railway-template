[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/hievents-1?utm_medium=integration&utm_source=button&utm_campaign=hi-events)

# Hi.Events on Railway

Railway template for [Hi.Events](https://github.com/HiEventsDev/Hi.Events), the open-source event management and ticket selling platform (AGPL-3.0).

## What it deploys

| Service | Source | State |
|---|---|---|
| **Hi.Events** | this repo: `Dockerfile` pins the official all-in-one image `daveearley/hi.events-all-in-one:v2.2.0@sha256:cd22770b…` (nginx, PHP-FPM, the Node SSR frontend, the queue worker and the scheduler) plus `railway-start.sh` | volume on `/app/backend/storage` (uploaded images, logs) |
| **Postgres** | Railway Postgres | volume |
| **Redis** | Railway Redis (password protected) | volume; queue, cache |

The public service listens on `$PORT` (8080), answers the health check on `/api/up`, and runs database migrations on every start.

## Variables

Nothing to fill in. The template sets:

| Variable | Value |
|---|---|
| `APP_KEY` | `base64:${{secret(43,"…")}}` (Laravel encryption key, generated) |
| `JWT_SECRET` | `${{secret(48)}}` (login tokens, generated) |
| `APP_SSR_SHARED_SECRET` | `${{secret(48)}}` (frontend to backend, generated) |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` |
| `PORT` | `8080` |

`railway-start.sh` derives `APP_URL`, `APP_FRONTEND_URL`, `APP_CDN_URL` and the `VITE_*` URLs from the service's Railway domain. With a custom domain, set `APP_PUBLIC_URL=https://tickets.example.com` and redeploy. Any variable you set on the service wins over the wrapper's default.

Optional, set on the service when you need them (see the [upstream variable list](https://hi.events/docs/getting-started/deploying)):

- **Email** (confirmations, tickets, password resets): `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_ENCRYPTION`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME`. Until then, emails go to the log only.
- **Stripe** (paid tickets): `STRIPE_PUBLIC_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `VITE_STRIPE_PUBLISHABLE_KEY`. Webhook URL: `https://YOUR-DOMAIN/api/public/webhooks/stripe`.
- **Close sign-ups** after you have created your account: `APP_DISABLE_REGISTRATION=true`.

## After deploying

1. Open the service's URL and go to `/auth/register`. The first account you create owns the organizer account. Registration is open until you set `APP_DISABLE_REGISTRATION=true`.
2. Create an organizer, then your first event.
3. Add email and Stripe settings when you are ready to sell.

## Updates

The Hi.Events service builds from this repo. When the pinned version is bumped on `main`, Railway shows deployers an "update available" notice, and you choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Migrations run automatically on start; back up Postgres before a major version.

## Local test

```sh
docker build -t hi-events-railway .
```

Run it with the variables above, a Postgres 17+ and a Redis. Licence: this wrapper is MIT; Hi.Events itself is AGPL-3.0.
