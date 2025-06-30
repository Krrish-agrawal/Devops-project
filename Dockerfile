# ---------- 1. Build & run the whole app ----------
# ──────────────────────────────────────────────────
# Multi-stage build: first stage compiles the React client,
# second stage runs the Node/Express server that also serves
# the static client files.

########################
# -- Stage 1: builder --
########################
FROM node:lts-slim AS builder

# Create app directory
WORKDIR /app

# Install dependencies separately to leverage Docker cache
COPY Client/package*.json ./Client/
COPY Server/package*.json ./Server/

RUN cd Client && npm ci && \
    cd ../Server && npm ci --production

# Copy full source
COPY Client/public ./Client/public
COPY Client/src ./Client/src
COPY Client/tailwind.config.js ./Client/
COPY Client/postcss.config.js ./Client/
COPY Client/tsconfig.json ./Client/   # Remove if not using TS
COPY Server ./Server

# Build React front-end (with CI mode + keep-alive echo)
RUN cd Client && \
    CI=true npm run build & \
    pid=$!; \
    while kill -0 $pid 2>/dev/null; do echo "⚙️ Building React app..."; sleep 30; done; \
    wait $pid

########################
# -- Stage 2: runner --
########################
FROM node:lts-slim

# Set working directory
WORKDIR /app

# Copy only what we need from builder image
COPY --from=builder /app/Client/build        /app/Client/build
COPY --from=builder /app/Server              /app/Server
COPY --from=builder /app/Server/node_modules /app/Server/node_modules

# Tell Express where the static files live (if code expects env var)
ENV CLIENT_BUILD_PATH=/app/Client/build

# Expose the port your Express server listens on
EXPOSE 5000

# Default command: start the server
CMD ["node", "/app/Server/index.js"]
