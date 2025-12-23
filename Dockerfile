# syntax=docker/dockerfile:1.4
FROM --platform=$BUILDPLATFORM golang:1.24 AS builder
LABEL maintainer="avesha system"

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Copy go mod files first for better layer caching
COPY go.mod go.sum ./

# Download dependencies with cache mount for faster builds
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy source code
COPY main.go ./
COPY util/ util/

# Build the binary for the target platform
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -a -trimpath -ldflags="-w -s" -o generator main.go

# Final stage - use target platform for alpine
FROM --platform=$TARGETPLATFORM alpine:3.15
LABEL maintainer="avesha system"

WORKDIR /app

# Install dependencies in a single layer
RUN apk add --update --no-cache \
    openvpn \
    jq \
    openssl \
    wireguard-tools \
    && rm -rf /var/cache/apk/*

# Copy application files
COPY logs/ logs/
COPY ovpn/ ovpn/
COPY wireguard/ wireguard/
COPY generate-certs.sh generate-certs.sh
COPY entrypoint.sh entrypoint.sh

# Set executable permissions
RUN chmod +x generate-certs.sh entrypoint.sh \
    && chmod +x wireguard/scripts/gen_key.sh

# Copy binary from builder
COPY --from=builder /app/generator /app/generator

# Set environment variables
ENV SRC_DIR="/app" \
    WORK_DIR="/work"

# Use exec form for better signal handling
CMD ["/app/entrypoint.sh"]
