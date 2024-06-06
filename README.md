# besu-qbft-k8s

This repository hosts Kubernetes manifests for deploying a Hyperledger Besu network configured with the Quorum Byzantine Fault Tolerance (QBFT) consensus mechanism. This setup is based on the implementation guidelines of the Brazilian Central Bank's DREX platform. The provided configuration files (config.toml and genesis.json) have been adapted from the original Central Bank implementation [see here](https://github.com/bacen/pilotord-kit-onboarding).

## Prerequisites

Ensure you have the following installed:
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [minikube](https://minikube.sigs.k8s.io/docs/start/)

## Setup Instructions

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

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

## 10. Cleanup

To delete the deployment, run:
```bash
kubectl delete namespace besu
```

## Conclusion

You have now successfully deployed a Hyperledger Besu QBFT network on Kubernetes using Minikube. You can extend this setup for more complex deployments and integrate with other tools as needed.