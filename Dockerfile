# ---------- 1. Build & run the whole app ----------
# ──────────────────────────────────────────────────
# Multi-stage build: first stage compiles the React client,
# second stage runs the Node/Express server that also serves
# the static client files.

########################
# -- Stage 1: builder --
########################
FROM node:lts-alpine AS builder

# Create app directory
WORKDIR /app

# Copy dependency manifests for both client & server
COPY Client/package*.json ./Client/
COPY Server/package*.json ./Server/

# Install dependencies separately to leverage Docker cache
RUN cd Client  && npm ci && \
    cd ../Server && npm ci --production

# Copy full source
COPY Client ./Client
COPY Server ./Server

# Build React front-end
RUN cd Client && npm run build

########################
# -- Stage 2: runner --
########################
FROM node:lts-alpine

# Set working directory
WORKDIR /app

# Copy only what we need from builder image
#  – built static assets
#  – server code with its node_modules
COPY --from=builder /app/Client/build        /app/Client/build
COPY --from=builder /app/Server              /app/Server
COPY --from=builder /app/Server/node_modules /app/Server/node_modules

# Tell Express where the static files live (if code expects env var)
ENV CLIENT_BUILD_PATH=/app/Client/build

# Expose the port your Express server listens on
EXPOSE 5000

# Default command: start the server
CMD ["node", "/app/Server/index.js"]
