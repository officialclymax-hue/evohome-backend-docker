# ---------- build stage ----------
FROM node:20-alpine AS builder
WORKDIR /app

# 1) Install deps
COPY package.json package-lock.json* ./
RUN npm install

# 2) Prisma client
COPY prisma ./prisma
RUN npx prisma generate

# 3) Copy source and build
COPY tsconfig*.json nest-cli.json ./
COPY src ./src
COPY public ./public
# seed code is inside src, included in build
RUN npm run build

# 4) Copy content seed doc (if present in repo)
COPY bolt-export.docx ./bolt-export.docx

# ---------- runtime stage ----------
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=8080

# Copy built app and deps from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/public ./public
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/bolt-export.docx ./bolt-export.docx

# On boot: sync DB, seed once, start API
CMD sh -lc "npx prisma db push && node dist/prisma/seed/seed.js && node dist/main.js"
