# Image URL to use all building/pushing image targets
IMG ?= aveshasystems/gateway-certs-generator:latest

.PHONY: docker-build
docker-build: ## Build docker image with the manager.
	docker build -t ${IMG} .