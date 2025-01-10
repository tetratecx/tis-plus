# Onboarding of a TIS cluster in Hosted Management Plane

## Step-0 
### Prerequistes 
1.  Download tetrate controlplane images - [Doc: https://docs.tetrate.io/istio-subscription-plus/installation/tisplus-images]
    - Requires Tetrate provided credentials
    - Then follow this script :- `./controlplane/sync_images.sh`
2.  Download tetrate `tctl` utility

## Step-1
Follow onboarding Doc for detailed guide: https://docs.tetrate.io/istio-subscription-plus/installation/onboard-cluster

We'll install tetrate controlplane components in a separate namespace. Make sure `kubectl` is pointing to the right k8s cluster that you want to onboard in management plane.

1.  If you have `tctl` utility available follow below steps or skip to point 2 -

    ``` 
    MP_HOST="hosted-mp.tetrate.io" MP_PASSWORD='mp_password' TCTL="./tctl-bin/tctl-amd64" CLUSTER="test-cluster" ./controlplane/onboard-tis-controlplane.sh
    ```
    - CLUSTER - It doesn't need to be app k8s cluster name, it can be any. Your app k8s cluster will be referenced with this name in managed MP.

    - MP_HOST -  management plane hostname, exclude `htpp/s` and port number.

    Now run -

    ```
    CLUSTER="test-cluster" HUB='docker_hub' MP_HOST="hosted-mp.tetrate.io"   ./controlplane/tis-controlplane-setup.sh
    ```

    - CLUSTER - same as you earlier provided
    - HUB - Your docker image registry where Tetrate images have been stotred


2.  When you don't have `tctl` utlity available -
    - Login to Tetrate hosted MP UI.
    - In clusters list , add one cluster object. Download Helm values file and place it here at root directory.
    - Make note of the cluster name you just provided.
    - Execute -
    ```
    CLUSTER="<cluster_name_just_provided>" HUB='<docker_hub>' MP_HOST="hosted-mp.tetrate.io" IMAGE_PULL_SECRET=''  ./controlplane/tis-controlplane-setup.sh
    ```
    - CLUSTER - same as you just provided
    - HUB - Your docker image registry where Tetrate images have been stored

3. In `tis-plus-system` namespace, there must run following pods -
    > k get po -n tis-plus-system
    ```
    NAME                                         READY   STATUS    RESTARTS      AGE
    edge-5f564cc56f-4vmrr                        1/1     Running   0             28h
    oap-deployment-58786c7675-vjtr6              2/2     Running   0             28h
    otel-collector-7d887b47cb-rd9gd              2/2     Running   0             28h
    tsb-operator-control-plane-895f7f47f-87cvg   1/1     Running   0             28h
    xcp-operator-edge-65b756545d-kzkj7           1/1     Running   0             28h
    ```
4. Make sure all above pods are in `READY` state

## Step-2 
Note: If you have opted for "Default: Automatic Tis+ sink" option [this is default option in step 1], you can skip this step-2.

Now, we'll customize existing istio observability and tracing configuration to point to newly deployed controlplane components.

1. Existing istio config should have customized configurations as mentioned in file -

```
    ./tid/tid-istio-values.yaml
```

2. Once istio config is in place, istiod pod must be restarted.
3. Now restart all of your app pods.
4.  Verification in MP UI -
    - Login TSB management plane
    - Select Clusters and select newly onboarded cluster.
    - Verify its services
5.  Verification in config-
    - Check envoy filter-chain for any service listener, it'll have following as part of http_connection_manager filter chain and tracing -
    > istioctl proxy-config listener <any_app_pod>  -n <namespace> --port <service_port> -oyaml
    
    Example snippet -
```
    filterChains:
    - filters:
        - name: envoy.filters.network.http_connection_manager
        typedConfig:
            '@type': type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
            accessLog:
            - name: envoy.access_loggers.http_grpc
            typedConfig:
                '@type': type.googleapis.com/envoy.extensions.access_loggers.grpc.v3.HttpGrpcAccessLogConfig
                commonConfig:
                filterStateObjectsToLog:
                - wasm.upstream_peer
                - wasm.upstream_peer_id
                - wasm.downstream_peer
                - wasm.downstream_peer_id
                grpcService:
                    envoyGrpc:
                    authority: oap.tis-plus-system.svc.cluster.local
                    clusterName: outbound|11800||oap.tis-plus-system.svc.cluster.local
                logName: http_envoy_accesslog
                transportApiVersion: V3
            forwardClientCertDetails: SANITIZE_SET
```

and

```
    tracing:
        provider:
            name: envoy.tracers.zipkin
            typedConfig:
                '@type': type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
                collectorCluster: outbound|9411||zipkin.tis-plus-system.svc.cluster.local
                collectorEndpoint: /api/v2/spans
                collectorEndpointVersion: HTTP_JSON
                collectorHostname: zipkin.tis-plus-system.svc.cluster.local
                sharedSpanContext: false
                traceId128bit: true
```

## Step-3

### Services visibility in Managementplane Dashboard

You need to create Tetrate heirarchy resources to organize all onboarded clusters and their services.
Tetrate heirarchy -

**ORG -> Tenant -> Workspaces**

* ORG - Org name is fixed, you can get it from MP UI right hand side user profile section.
* Tenant - It represents one Team.
* Workspace - It represents logically grouped applications namespaces across clusters.

1. Login to MP UI
2. Under Tenants, create one tenant
3.  Under workspace, first select your tenant and create a new workspace.
    - It'll ask to select cluster and namespaces to include. Here we keep logically connected namespaces where we want them in a single view of topology.
    - We can create as many workspaces as we want under one tenant.

Note - To automate above heirarchy creation steps, you can follow -

```
./controlplane/mp-dashboard/tsb.sh
```

# Known Issues


# Done
