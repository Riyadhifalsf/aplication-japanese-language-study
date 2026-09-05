FROM node:20-alpine
RUN apk add --no-cache postgresql-client
WORKDIR /app
COPY api/package.json ./
RUN npm install --omit=dev
COPY api/src ./src
COPY api/db ./db
COPY data ./data
COPY api/entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/app/entrypoint.sh"]
