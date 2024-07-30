FROM golang:1.22.5-alpine3.20 as builder
LABEL maintainer="avesha system"
WORKDIR /app
# Copy the go source
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download
COPY main.go main.go
COPY util/ util/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o generator main.go

FROM alpine:3.20.1
WORKDIR /app
# Install dependencies including a specific version of OpenSSL
RUN apk add --no-cache \
    openvpn \
    jq \
    wget \
    ca-certificates && \
    wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz && \
    tar -zxvf openssl-1.1.1w.tar.gz && \
    cd openssl-1.1.1w && \
    ./config && \
    make && \
    make install && \
    cd .. && \
    rm -rf openssl-1.1.1w.tar.gz openssl-1.1.1w \
    
COPY logs/ logs/
COPY ovpn/ ovpn/
COPY generate-certs.sh generate-certs.sh
RUN chmod +x generate-certs.sh
COPY --from=builder /app/generator /app/generator
ENV SRC_DIR "/app"
ENV WORK_DIR "/work"
CMD /app/generate-certs.sh

