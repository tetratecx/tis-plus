# tis-plus

**Onboarding of a TIS cluster in Hosted Management Plane**

**Step-0**
*PREREQUISITE*
1. Download tetrate CP images-
    a. Requires skopeo - https://github.com/containers/skopeo/blob/main/install.md
    b. Follow :- `./controlplane/sync_images.sh`
2. Download tetrate `tctl` utility (optional)

**Step-1**
We'll install tetrate controlplane components in a separate namespace. Make sure `kubectl` is pointing to the right k8s cluster that you want to onboard in management plane.
a. If you have `tctl` utility available follow below steps OR skip to point (b)-
    ``` 
    MP_HOST="hosted-mp.tetrate.io" MP_PASSWORD='mp_password' TCTL="./tctl-bin/tctl-amd64" CLUSTER="test-cluster" ./controlplane/onboard-tis-controlplane.sh
    ```
    *CLUSTER - It doesn't need to be app k8s cluster name, it can be any. Your app k8s cluster will be referenced with this name in managed MP.*

    *MP_HOST -  management plane hostname, exclude `htpps` and port number.* 

    Now run -
    ```
    CLUSTER="test-cluster" HUB='docker_hub' MP_HOST="hosted-mp.tetrate.io"   ./controlplane/tis-controlplane-setup.sh
    ```
    *CLUSTER - same as you earlier provided*
    *HUB - Your docker image registry where Tetrate images have been stotred*


b. When you don't have `tctl` utlity available -
    i. Login to Tetrate hosted MP UI.
    ii. In clusters list , add one cluster object. Download Helm values file and place it here at root directory.
    iii. Make note of the cluster name you just provided.
    iv. Execute -
        ```
        CLUSTER="<cluster_name_just_provided>" HUB='<docker_hub>' MP_HOST="hosted-mp.tetrate.io"   ./controlplane/tis-controlplane-setup.sh
        ```
    *CLUSTER - same as you just provided*
    *HUB - Your docker image registry where Tetrate images have been stotred*


c. In `tis-plus-system` namespace, there must run following pods -
    >k get po -n tis-plus-system
    NAME                                         READY   STATUS    RESTARTS      AGE
    edge-5f564cc56f-4vmrr                        1/1     Running   0             28h
    oap-deployment-58786c7675-vjtr6              2/2     Running   0             28h
    otel-collector-7d887b47cb-rd9gd              2/2     Running   0             28h
    tsb-operator-control-plane-895f7f47f-87cvg   1/1     Running   0             28h
    xcp-operator-edge-65b756545d-kzkj7           1/1     Running   0             28h
d. Make sure all above pods are in READY state

**Step-2**

Now, we'll customize existing istio observability and tracing configuration to point to newly deployed controlplane components.

a. Existing istio config should have customized configurations as mentioned in file https://github.com/tetratecx/tis-plus/tid/tid-istio-values.yaml
    ```
    global:
    meshID: mesh1
    multiCluster:
        clusterName: Kubernetes
    network: ""
    meshConfig:
    defaultConfig:
        envoyMetricsService:
        address: "oap.tis-plus-system.svc:11800"
        tlsSettings:
            mode: DISABLE
        tcpKeepalive:
            probes: 3
            time: 10s
            interval: 10s
        tracing:
            sampling: 0.01
    defaultProviders:
        tracing:
        - tetrate-oap
        accessLogging:
        - tetrate-oap-als
    extensionProviders:
        - name: tetrate-oap
        zipkin:
            service: zipkin.tis-plus-system.svc.cluster.local
            port: 9411
        - name: tetrate-oap-als
        envoyHttpAls:
            service: oap.tis-plus-system.svc.cluster.local
            port: 11800
    enableTracing: true
    accessLogFile: /dev/stdout
    enableEnvoyAccessLogService: true
    pilot:
    env:
        PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION: true
        PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS: true
    ```
b. Once istio config is in place, istiod pod must be restarted.
c. Now restart all of your app pods.
d. Verification in MP UI -
    i. Login TSB management plane
    ii. Select Clusters and select newly onboarded cluster.
    iii. Verify its services
e. Verification in config-
    i. Check envoy filter-chain for any service listener, it'll have following as part of http_connection_manager filter chain and tracing -
    `istioctl proxy-config listener <any_app_pod>  -n <namespace> --port <service_port> -oyaml`
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

**Step-3**
# Services visibility in Managementplane Dashboard

You need to create Tetrate heirarchy resources to organize all onboarded clusters and their services.
Tetrate heirarchy -
ORG -> Tenant -> Workspaces

* ORG - Org name is fixed, you can get it from MP UI right hand side user profile section.
* Tenant - It represents one Team.
* Workspace - It represents logically grouped applications namespaces across clusters.

a. Login to MP UI
b. Under Tenants, create one tenant
c. Under workspace, first select your tenant and create a new workspace.
    i. It'll ask to select cluster and namespaces to include. Here we keep logically connected namespaces where we want them in a single view of topology.
    ii. We can create as many workspaces as we want under one tenant.

Note - To automate above steps, you can follow -
```
./controlplane/mp-dashboard/tsb.sh
```

**Done**