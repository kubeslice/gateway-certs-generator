# gateway-certs-generator

This is an opinionated single-file OpenVPN TLS certificate configuration generator for slice gateways. it is an enhancement to easy-rsa (typically bundled with OpenVPN).

easy-rsa is a CLI utility to build and manage a PKI CA. In laymen's terms, this means to create a root certificate authority, and request and sign certificates, including intermediate CAs and certificate revocation lists (CRL).

## Getting Started
It is strongly recommended to use a released version. Follow the instructions in this [document](https://docs.avesha.io/opensource/installing-the-kubeslice-controller).

## Building and Deploying `gateway-certs-generator` and use with `kubeslice-controller` in a Local Kind Cluster
For more information, see [getting started with kind clusters](https://docs.avesha.io/opensource/getting-started-with-kind-clusters).

### Prerequisites

* Docker installed and running in your local machine
* A running [`kind`](https://kind.sigs.k8s.io/)  cluster
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/) installed and configured
* Follow the getting started from above, to install [`kubeslice-controller`](https://github.com/kubeslice/kubeslice-controller) and [`worker-operator`](https://github.com/kubeslice/worker-operator)

### Setting up Your Helm Repo
If you have not added avesha helm repo yet, add it.

```console
helm repo add avesha https://kubeslice.github.io/charts/
```

Upgrade the avesha helm repo.

```console
helm repo update
```

### Build Your Docker Image
#### Latest docker image - [gateway-certs-generator](https://hub.docker.com/r/aveshasystems/gateway-certs-generator)

1. Clone the latest version of gateway-certs-generator from  the `master` branch.

```console
git clone https://github.com/kubeslice/gateway-certs-generator.git
cd gateway-certs-generator
```

2. Adjust image name variable `IMG` in the [`Makefile`](Makefile) to change the docker tag to be built.
   Default image is set as `IMG ?= aveshasystems/gateway-certs-generator:latest`. Modify this if required.

```console
make docker-build
```
### Running Local Image on Kind Clusters

1. Loading gateway-certs-generator Image into your kind cluster ([kind](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster)).
   If needed, replace `aveshasystems/gateway-certs-generator` with your locally built image name in the previous step.
   
* Note: If using a named cluster you will need to specify the name of the cluster you wish to load the images into. See [loading an image into your kind cluster](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).
```console
kind load docker-image aveshasystems/gateway-certs-generator --name cluster-name
```
Example
```console
kind load docker-image aveshasystems/kubeslice-controller --name kind
```

2. Check the loaded image in the cluster. Modify node name if required.

* Note: `kind-control-plane` is the name of the Docker container. Modify if needed.
```console
docker exec -it kind-control-plane crictl images
```

### Deploying in a Cluster
1. Create chart values file `yourvaluesfile.yaml`. Refer to [values.yaml](https://github.com/kubeslice/charts/blob/master/charts/kubeslice-controller/values.yaml) on how to adjust this and update the `kubeslice-controller` image to the local build image.

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
````

2. Deploy the updated chart.

```console
make chart-deploy VALUESFILE=yourvaluesfile.yaml
```

### Verify if the Operator is Running


```console
kubectl get pods -n kubeslice-controller
```

Sample output to expect

```
NAME                                            READY   STATUS    RESTARTS   AGE
kubeslice-controller-manager-5b548fb865-kzb7c   2/2     Running   0          102s
```

### Uninstalling the kubeslice-controller
For more information, see [uninstalling the KubeSlice](https://docs.avesha.io/opensource/uninstalling-kubeslice).

```console
make chart-undeploy
 ```

## License

Apache License 2.0
