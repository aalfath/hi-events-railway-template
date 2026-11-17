#!/bin/sh
# Railway wrapper for the Hi.Events all-in-one image.
# Fills in sensible defaults, prepares the storage volume, makes nginx listen
# on $PORT, then hands over to the image's own /startup.sh (migrations + supervisord).
set -e

PORT="${PORT:-80}"

# Public URL: APP_PUBLIC_URL wins (set it when you add a custom domain),
# else the Railway domain of this service.
if [ -n "${APP_PUBLIC_URL:-}" ]; then
  BASE_URL="${APP_PUBLIC_URL%/}"
elif [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
else
  BASE_URL="http://localhost:${PORT}"
fi

export APP_URL="${APP_URL:-$BASE_URL}"
export APP_FRONTEND_URL="${APP_FRONTEND_URL:-$BASE_URL}"
export APP_CDN_URL="${APP_CDN_URL:-$BASE_URL/storage}"
export VITE_FRONTEND_URL="${VITE_FRONTEND_URL:-$BASE_URL}"
export VITE_API_URL_CLIENT="${VITE_API_URL_CLIENT:-$BASE_URL/api}"
export VITE_API_URL_SERVER="http://localhost:${PORT}/api"
export VITE_STRIPE_PUBLISHABLE_KEY="${VITE_STRIPE_PUBLISHABLE_KEY:-}"
export VITE_APP_NAME="${VITE_APP_NAME:-Hi.Events}"

export APP_ENV="${APP_ENV:-production}"
export APP_DEBUG="${APP_DEBUG:-false}"
export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"
export DB_CONNECTION="${DB_CONNECTION:-pgsql}"
export QUEUE_CONNECTION="${QUEUE_CONNECTION:-redis}"
export CACHE_DRIVER="${CACHE_DRIVER:-redis}"
export FILESYSTEM_PUBLIC_DISK="${FILESYSTEM_PUBLIC_DISK:-public}"
export FILESYSTEM_PRIVATE_DISK="${FILESYSTEM_PRIVATE_DISK:-local}"
export APP_DISABLE_REGISTRATION="${APP_DISABLE_REGISTRATION:-false}"
export APP_SAAS_MODE_ENABLED="${APP_SAAS_MODE_ENABLED:-false}"
export APP_TRUSTED_PROXIES="${APP_TRUSTED_PROXIES:-*}"
export MAIL_MAILER="${MAIL_MAILER:-log}"
export WEBHOOK_QUEUE_NAME="${WEBHOOK_QUEUE_NAME:-webhook-queue}"

for v in APP_KEY JWT_SECRET DATABASE_URL; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then
    echo "ERROR: $v is not set. The Railway template generates it; set it on the service." >&2
    exit 1
  fi
done
if [ -z "${REDIS_URL:-}" ] && [ -z "${REDIS_HOST:-}" ]; then
  echo "ERROR: REDIS_URL is not set (queue worker needs Redis)." >&2
  exit 1
fi

# Wait for Postgres (on a fresh deploy it can start after the app).
i=0
until php -r '$u=parse_url(getenv("DATABASE_URL")); try { new PDO(sprintf("pgsql:host=%s;port=%d;dbname=%s",$u["host"],$u["port"]??5432,ltrim($u["path"]??"/postgres","/")), urldecode($u["user"]??""), urldecode($u["pass"]??""), [PDO::ATTR_TIMEOUT=>3]); } catch (Throwable $e) { exit(1); }' 2>/dev/null; do
  i=$((i+1))
  if [ "$i" -ge 60 ]; then echo "ERROR: database not reachable after 3 minutes." >&2; exit 1; fi
  echo "Waiting for the database ($i)..."
  sleep 3
done

# The volume is mounted on /app/backend/storage and starts empty.
S=/app/backend/storage
mkdir -p "$S/app/public" "$S/app/private" "$S/fonts" "$S/logs" \
  "$S/framework/cache/data" "$S/framework/sessions" "$S/framework/views"
rm -rf "$S/lost+found"

# Listen on Railway's $PORT and point the SSR frontend at it.
sed -i -E "s/listen (\[::\]:)?[0-9]+;/listen \1${PORT};/g" /etc/nginx/nginx.conf
sed -i -E "s#http://localhost:[0-9]+/api#http://localhost:${PORT}/api#g" /etc/supervisord.conf

echo "Hi.Events: public URL ${BASE_URL}, listening on ${PORT}"
exec /startup.sh
