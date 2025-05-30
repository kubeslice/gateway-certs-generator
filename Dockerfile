FROM golang:1.24 as builder
LABEL maintainer="avesha system"

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
# Copy the go source
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download
COPY main.go main.go
COPY util/ util/
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -o generator main.go

FROM alpine:latest
WORKDIR /app
RUN apk add openvpn jq openssl
COPY logs/ logs/
COPY ovpn/ ovpn/
COPY generate-certs.sh generate-certs.sh
RUN chmod +x generate-certs.sh
COPY --from=builder /app/generator /app/generator
ENV SRC_DIR "/app"
ENV WORK_DIR "/work"
CMD /app/generate-certs.sh
