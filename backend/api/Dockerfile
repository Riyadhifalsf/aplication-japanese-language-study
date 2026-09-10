FROM node:24-alpine

RUN apk add --no-cache postgresql-client \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app
ENV NODE_ENV=production

COPY api/package.json ./
RUN npm install --omit=dev --no-audit --no-fund \
    && npm cache clean --force

COPY api/src ./src
COPY api/db ./db
COPY data ./data
COPY api/entrypoint.sh ./entrypoint.sh

RUN chmod +x entrypoint.sh \
    && sed -i 's/\r$//' entrypoint.sh \
    && chown -R appuser:appgroup /app

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/api/health >/dev/null || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
