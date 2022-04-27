FROM golang:1.17 as builder
LABEL maintainer="avesha system"
WORKDIR /app
# Copy the go source
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download
COPY main.go main.go
COPY util/ util/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o generator main.go

FROM debian:buster
WORKDIR /app
RUN apt-get --allow-releaseinfo-change update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openvpn jq

COPY logs/ logs/
COPY ovpn/ ovpn/
COPY generate-certs.sh generate-certs.sh
RUN chmod +x generate-certs.sh
COPY --from=builder /app/generator /app/generator
ENV SRC_DIR "/app"
ENV WORK_DIR "/work"
CMD /app/generate-certs.sh

