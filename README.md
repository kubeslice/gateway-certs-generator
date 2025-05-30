# Certificate Generator for Slice Gateway

The `gateway-certs-generator` is an opinionated single-file OpenVPN TLS certificate configuration generator for slice gateways. It enhances `easy-rsa` (typically bundled with OpenVPN).

`easy-rsa` is a CLI tool/utility to build and manage a PKI CA. use the CLI tool `easy-rsa`. Using the tool, create a root certificate authority, and request and sign certificates including intermediate CAs and certificate revocation lists (CRL).

## Get Started
It is strongly recommended that you use a released version.

Refer to our documentation on:
- [Get Started on KubeSlice](https://kubeslice.io/documentation/open-source/latest/category/get-started)
- [Install KubeSlice](https://kubeslice.io/documentation/open-source/latest/category/install-kubeslice)

## Build and Deploy Certificate Generator on a Kind Cluster

To generate certificates, the controller requires the 'gateway-cert-generator' image. So, we create the image and use the image version in the controller values file.

### Prerequisites
Before you begin, make sure the following prerequisites are met:
* Docker is installed and running on your local machine.
* A running [`kind`](https://kind.sigs.k8s.io/) cluster.
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/) is installed and configured.
* You have prepared the environment to install [`kubeslice-controller`](https://github.com/kubeslice/kubeslice-controller) on the controller cluster and [`worker-operator`](https://github.com/kubeslice/worker-operator) on the worker cluster. For more information, see [Prerequisites](https://kubeslice.io/documentation/open-source/1.3.0/category/prerequisites).

### Set up Your Helm Repo
If you have not added avesha `helm repo` yet, add it.

```console
helm repo add avesha https://kubeslice.github.io/charts/
```

Upgrade the avesha helm repo.

```console
helm repo update
```

### Build Your Docker Image

To download the latest docker image for gateway-certs-generator, click [here](https://hub.docker.com/r/aveshasystems/gateway-certs-generator).

1. Clone the latest version of gateway-certs-generator from  the `master` branch.

   ```console
   git clone https://github.com/kubeslice/gateway-certs-generator.git
   cd gateway-certs-generator
   ```

2. Modify the image name variable `IMG` in the [`Makefile`](Makefile) to change the docker tag to be built.
   The default image is set as `IMG ?= aveshasystems/gateway-certs-generator:latest`. Modify as needed.

   ```console
   make docker-build
   ```
### Run Local Image on Kind Cluster

1. Load the gateway-certs-generator image into your kind cluster ([kind](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster)).
   If needed, replace `aveshasystems/gateway-certs-generator` with your locally built image name in the previous step.
   
* Note: If you use a named cluster, specify the name of the cluster you wish to load the images into. See [loading an image into your kind cluster](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).
  
   ```console
   kind load docker-image aveshasystems/gateway-certs-generator --name cluster-name
   ```
   Example
   ```console
   kind load docker-image aveshasystems/kubeslice-controller --name kind
   ```

2. Check the loaded image in the cluster. Modify the node name if required.

* Note: `kind-control-plane` is the name of the Docker container. Modify as needed. 
  
  ```console
  docker exec -it kind-control-plane critical images
  ```

### Deploy the Certificate Generator on a Cluster
1. Create the chart values file called `yourvaluesfile.yaml`. Refer to [values.yaml](https://github.com/kubeslice/charts/blob/master/charts/kubeslice-controller/values.yaml) to update the `kubeslice-controller` image to the local build image.

From the sample:

   ```
   kubeslice:
   ---
   ---
      ovpnJob:
      ---
      ---
         image: aveshasystems/gateway-certs-generator
         tag: 0.1.0
   ```

Change it to:

   ```
   kubeslice:
   ---
   ---
      ovpnJob:
      ---
      ---
         image: <my-custom-image> 
         tag: <unique-tag>
   ```

2. Deploy the updated chart.

   ```console
   make chart-deploy VALUESFILE=yourvaluesfile.yaml
   ```

### Uninstall the KubeSlice Controller
For more information, see [uninstalling KubeSlice](https://kubeslice.io/documentation/open-source/1.3.0/uninstall-kubeslice/).

```console
make chart-undeploy
 ```
 

## License

Apache License 2.0
