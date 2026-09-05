#!/bin/sh
set -e
echo "Applying schema..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f /app/db/schema.sql
echo "Creating admin..."
node /app/src/create-admin.js || true
echo "Seeding content..."
node /app/src/seed.js
echo "Starting API..."
exec node /app/src/server.js
