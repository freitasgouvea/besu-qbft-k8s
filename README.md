# besu-qbft-k8s

This repository hosts Kubernetes manifests for deploying a Hyperledger Besu network configured with the Quorum Byzantine Fault Tolerance (QBFT) consensus mechanism. This setup is based on the implementation guidelines of the Brazilian Central Bank's DREX platform. The provided configuration files (config.toml and genesis.json) have been adapted from the original Central Bank implementation [see here](https://github.com/bacen/pilotord-kit-onboarding).

## Prerequisites

Ensure you have the following installed:
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [minikube](https://minikube.sigs.k8s.io/docs/start/)

## TL;DR

If you want to quickly deploy all artifacts, start Minikube or any other tool that allows you to run Kubernetes in your local environment and run the make command:
```bash
make
```

After testing you can delete all the resources using this command:

```bash
make clean
```

## Setup Instructions

Follow these steps to deploy, run and test this project on your local machine.

### 1. Start Minikube

Start your minikube cluster:
```bash
minikube start
```

### 2. Create Namespace

Create the `besu` namespace:
```bash
kubectl apply -f namespace
```

**Namespace**
- `namespace/besu-namespace.yaml`: Defines a namespace called `besu` to isolate all Besu-related resources within the Kubernetes cluster.

### 3. Deploy ConfigMaps

Create the ConfigMaps for Besu configuration:
```bash
kubectl apply -f configmap
```

**ConfigMaps**
- `configmap/besu-config-toml-configmap.yaml`: Contains the Besu node configuration (`config.toml`), which includes settings for logging, networking, transaction pool, JSON-RPC, and metrics.
- `configmap/besu-genesis-configmap.yaml`: Contains the genesis block configuration (`genesis.json`), which defines the initial state and consensus parameters for the blockchain.

### 4. Deploy Secrets

Create the secrets for your Besu nodes:
```bash
kubectl apply -f secrets
```

**Secrets**
- `secrets/node1-keys-secret.yaml`, `secrets/node2-keys-secret.yaml`, `secrets/node3-keys-secret.yaml`, `secrets/node4-keys-secret.yaml`:  Stores the private and public keys for for Nodes 1, 2, 3, and 4 respectively.

These keys are essential for the nodes to participate in the QBFT consensus mechanism securely.

**IMPORTANT**
- Do not use the keys provided in these files in any productive enviroments for security reasons.

### 5. Deploy Services

Create services to expose your Besu nodes:
```bash
kubectl apply -f services
```

**Services**
- `services/node1-service.yaml`, `services/node2-service.yaml`, `services/node3-service.yaml`, `services/node4-service.yaml`:: Defines the service to expose each node, including ports for P2P discovery, RLPx, JSON-RPC, WebSockets, and GraphQL.

These services ensure that the Besu nodes can communicate with each other and be accessed externally for API requests.

### 6. Deploy StatefulSets

Deploy Besu nodes using StatefulSets:
```bash
kubectl apply -f statefulsets
```

**StatefulSets**
- `statefulsets/node1-statefulset.yaml`: Manages the deployment and scaling of Node 1 (bootnode). It includes the service account, role, and role binding for accessing secrets and services, and mounts the required volumes.
- `statefulsets/node2-statefulset.yaml`, `statefulsets/node3-statefulset.yaml`, `statefulsets/node4-statefulset.yaml`: Manage the deployment and scaling of Nodes 2, 3, and 4 respectively. These nodes include the bootnode-specific (Node 1) argument to join the network.

### 7. Verify Deployment

Check the status of your pods:
```bash
kubectl get pods -n besu
```

Check the services:
```bash
kubectl get svc -n besu
```

### 8. Accessing Besu

To interact with the Besu nodes, you can use port forwarding:
```bash
kubectl port-forward svc/besu-node1 8545:8545 -n besu
```

This will forward the Besu JSON-RPC interface to `localhost:8545`.

### 9. Testing Nodes Functionality

To verify that all four nodes are operational and communicating correctly within the network, you can use the JSON-RPC API to request the node count and peer connections. Use `curl` to send a JSON-RPC request from your local machine:

1. **Check Node Peers**: This checks the peer count to ensure that the nodes are connected to the network. Replace `localhost:8545` with the respective forwarded port number for each node.

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' -H "Content-Type: application/json" http://localhost:8545
```

This command should return the number of peers each node is connected to. For a fully connected 4-node network, each node should list 3 peers (excluding itself).

2. **Get Node Info**: To fetch more detailed information about each node, such as its ID and connected peers, use the following command:

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' -H "Content-Type: cannot accept/json" http://localhost:8545
```

This command returns information about the node’s Ethereum network identity, client version, network capabilities, and more.

By executing these tests, you can ensure that the network is fully operational and each node is correctly configured.

### 10. Cleanup

To delete the deployment, run:
```bash
kubectl delete namespace besu
```

## Deploy on Azure

If you want to run this project on Azure Kubernetes Service (AKS) instead of a local environment using Minikube, you need to make several updates and adjustments to your setup. Here are the steps and considerations:

### Prerequisites

Ensure you have the following installed:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Create an AKS Cluster

Use the Azure CLI to create an AKS cluster. This includes creating a resource group, a virtual network, and the AKS cluster itself.

```bash
# Log in to your Azure account
az login

# Set your Azure subscription (if you have multiple subscriptions)
az account set --subscription "your-subscription-id"

# Create a resource group
az group create --name myResourceGroup --location eastus

# Register the Microsoft.Insights Resource Provider (in Windows)
az provider register --namespace Microsoft.Insights

# Create an AKS cluster
az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 4 --enable-addons monitoring --generate-ssh-keys --node-vm-size Standard_D2s_v3

# Get credentials for kubectl
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

### Deploy 

After that you can deploy the project 

```
make deploy
```

The artifcts deployed will shown on screen.

### Test

After exposing your Besu services to the internet via a LoadBalancer in AKS, you can test the setup by checking the external IP addresses assigned to your services and making requests to these endpoints. Here’s how to do it step-by-step:

### 1. Verify External IP Addresses

First, ensure that your services have been assigned external IP addresses. This might take a few minutes after you apply the service configurations.

Run the following command to get the external IP addresses:

```bash
kubectl get svc -n besu
```

You should see an output similar to this:

```plaintext
NAME          TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                         AGE
besu-node1    LoadBalancer   10.0.123.45    52.168.23.45    30303:30303/UDP,30303:30303/TCP 5m
besu-node2    LoadBalancer   10.0.123.46    52.168.23.46    30303:30303/UDP,30303:30303/TCP 5m
besu-node3    LoadBalancer   10.0.123.47    52.168.23.47    30303:30303/UDP,30303:30303/TCP 5m
besu-node4    LoadBalancer   10.0.123.48    52.168.23.48    30303:30303/UDP,30303:30303/TCP 5m
```

### 2. Test JSON-RPC Endpoints

You can test the JSON-RPC interface of each node by making HTTP requests to the external IP addresses. Here’s an example using `curl`:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://52.168.23.45:8545
```

If everything is set up correctly, you should get a response similar to:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "381660001"  # This will be your chain ID defined in genesis.json
}
```

Repeat this for each node's external IP to ensure they are all reachable.

### 3. Test P2P Network Connectivity

To ensure that your nodes can communicate with each other over the P2P network, you need to check the logs of each node for successful peer connections. Use the following command to check the logs:

```bash
kubectl logs <pod-name> -n besu
```

Replace `<pod-name>` with the name of your pod. You can get the pod names by running:

```bash
kubectl get pods -n besu
```

In the logs, look for entries indicating successful peer connections. You should see lines similar to:

```plaintext
2024-06-06 12:34:56.789+00:00 | p2p-discovery-worker-2 | INFO  | PeerDiscoveryAgent | Found 1 new peers
2024-06-06 12:34:57.123+00:00 | EthScheduler-Workers-2 | INFO  | EthereumWireProtocol | Successfully connected to peer: <peer-info>
```

### 4. Test with an RPC Method

You can further test by using different JSON-RPC methods. For example, to get the latest block number:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://52.168.23.45:8545
```

A successful response will look like:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x1"  # This is the block number in hexadecimal
}
```

### Summary

By following these steps, you can verify that your Besu nodes are correctly exposed to the internet and are functioning as expected. You’ll be able to interact with them using the JSON-RPC API and ensure they are properly connected within the P2P network.

## Conclusion

You have now successfully deployed a Hyperledger Besu QBFT network on Kubernetes using Minikube. You can extend this setup for more complex deployments and integrate with other tools as needed.