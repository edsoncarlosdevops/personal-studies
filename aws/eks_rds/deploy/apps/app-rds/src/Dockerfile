# ---- Stage 1: Instalar dependencias ----
FROM node:20-alpine AS deps

RUN apk add --no-cache libc6-compat

WORKDIR /app

COPY package.json ./
RUN npm ci --only=production --ignore-scripts

# ---- Stage 2: Imagem final ----
FROM node:20-alpine

RUN addgroup -S appgroup \
    && adduser -S appuser -G appgroup \
    && rm -rf /var/cache/apk/* /tmp/*

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --chown=appuser:appgroup . .
EXPOSE 3000

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1))"
CMD ["node", "server.js"]

