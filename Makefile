# Image URL to use all building/pushing image targets
IMG ?= aveshasystems/gateway-certs-generator:latest

.PHONY: docker-build
docker-build: ## Build docker image with the manager.
	docker buildx create --name container --driver=docker-container || true
	docker build --builder container --platform linux/amd64,linux/arm64 -t ${IMG} .

.PHONY: docker-push
docker-push: ## Push docker image with the manager.
	docker buildx create --name container --driver=docker-container || true
	docker build --push --builder container --platform linux/amd64,linux/arm64 -t ${IMG} .

.PHONY: chart-deploy
chart-deploy:
	## Deploy the artifacts using helm
	## Usage: make chart-deploy VALUESFILE=[valuesfilename]
	helm upgrade --install cert-manager avesha/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
	helm upgrade --install kubeslice-controller -n kubeslice-controller avesha/kubeslice-controller -f ${VALUESFILE} --create-namespace

.PHONY: chart-undeploy
chart-undeploy:
	helm uninstall kubeslice-controller -n kubeslice-controller
	helm uninstall cert-manager -n cert-manager

.PHONY: chart-deploy-cert
chart-deploy-cert:
	## Deploy the artifacts using helm
	helm upgrade --install cert-manager avesha/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true

.PHONY: chart-deploy-controller
chart-deploy-controller:
	## Deploy the artifacts using helm
    ## Usage: make chart-deploy VALUESFILE=[valuesfilename]
	helm upgrade --install kubeslice-controller -n kubeslice-controller avesha/kubeslice-controller -f ${VALUESFILE} --create-namespace