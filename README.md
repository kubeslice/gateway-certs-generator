# gateway-certs-generator

![Docker Image Size](https://img.shields.io/docker/image-size/aveshasystems/gateway-certs-generator/latest)
![Docker Image Version](https://img.shields.io/docker/v/aveshasystems/gateway-certs-generator?sort=date)

This is an opinionated single-file OpenVPN TLS certificate configuration generator for slice gateways. it is an enhancement to easy-rsa (typically bundled with OpenVPN).

easy-rsa is a CLI utility to build and manage a PKI CA. In laymen's terms, this means to create a root certificate authority, and request and sign certificates, including intermediate CAs and certificate revocation lists (CRL).


## Build Docker Image
```bash
make docker-build
```

