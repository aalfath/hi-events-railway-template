# Changelog

Each entry is one update of this template. Breaking changes are listed first. Railway shows deployers an "update available" notice when a change lands on `main`; read the entry before you apply it.

## 2.2.0-railway.1 (2026-11-17)

- First release of this template: Hi.Events **v2.2.0**, official image `daveearley/hi.events-all-in-one:v2.2.0` pinned by digest `sha256:cd22770bab1a705c869453ad66b8f82d1d7cfd1a59be951a3e655cb4ced4914b`.
- Railway Postgres and Redis (password protected), uploads on a volume at `/app/backend/storage`, `APP_KEY`, `JWT_SECRET` and `APP_SSR_SHARED_SECRET` generated per deploy.
- README: Deploy on Railway button for the published template `hi-events-1`.
- Start wrapper `railway-start.sh`: waits for Postgres, prepares the storage folders on the volume, makes nginx listen on `$PORT` and derives every public URL from the service's Railway domain (or `APP_PUBLIC_URL`).
