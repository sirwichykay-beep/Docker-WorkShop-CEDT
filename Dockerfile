# syntax=docker/dockerfile:1.7

# =============================================================================
# Builder stage — installs production dependencies only, on a fresh Node base.
# =============================================================================

# ใช้ node:20.11-slim และตั้งชื่อ stage ว่า builder
FROM node:20.11-slim AS builder

WORKDIR /app

# copy package files แล้วติดตั้ง dependencies (ไม่เอา dev)
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev

# copy source code ทั้งหมด
COPY app/src ./src

# =============================================================================
# Runtime stage — slim final image. Nothing from builder's caches leaks in.
# =============================================================================

# ใช้ base image เดียวกัน
FROM node:20.11-slim

WORKDIR /app

# copy app ที่ build เสร็จจาก builder
COPY --from=builder /app /app

ENV NODE_ENV=production
EXPOSE 3000

# healthcheck โดยใช้ Node (เพราะไม่มี curl/wget)
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

# start app
CMD ["node", "src/index.js"]