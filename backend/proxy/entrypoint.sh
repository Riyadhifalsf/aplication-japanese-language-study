#!/bin/sh
set -e
mkdir -p /etc/nginx/certs
IP="${DOMAIN:-192.168.100.11}"
if [ ! -f /etc/nginx/certs/cert.pem ] || [ ! -f /etc/nginx/certs/key.pem ]; then
  echo "Generating self-signed certificate for ${IP}..."
  openssl req -x509 -nodes -newkey rsa:3072 -days 3650 \
    -keyout /etc/nginx/certs/key.pem \
    -out /etc/nginx/certs/cert.pem \
    -subj "/CN=${IP}" \
    -addext "subjectAltName=IP:${IP},DNS:${IP}"
fi
exec "$@"
