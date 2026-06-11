FROM node:20-alpine

WORKDIR /app

# Cria usuario nao-root para seguranca
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia dependencias primeiro (cache)
COPY package.json ./
RUN npm ci --only=production

# Copia o codigo
COPY . .

# Ajusta permissoes
RUN chown -R appuser:appgroup /app

EXPOSE 3000

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["node", "server.js"]

