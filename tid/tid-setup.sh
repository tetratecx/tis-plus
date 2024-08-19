#!/usr/bin/env bash


TAG=1.22.2-tetrate1-distroless
VERSION=1.22.2

helm repo add tetratelabs https://tis.tetrate.io/charts
helm repo update tetratelabs

helm upgrade --install istio-base tetratelabs/base -n istio-system \
    --set global.tag=${TAG} \
    --set global.hub="containers.istio.tetratelabs.com" \
    --version ${VERSION}

helm upgrade --install istiod tetratelabs/istiod -n istio-system \
    -f tid-istio-values.yaml \
    --set global.tag=${TAG} \
    --set global.hub="containers.istio.tetratelabs.com" \
    --version ${VERSION}

###################
# Deploy bookinfo
#####################

# NAMESPACE="${NAMESPACE:-bookinfo}"
# kubectl create ns "${NAMESPACE}"
# kubectl label namespace "${NAMESPACE}" istio-injection=enabled

# helm upgrade --install bookinfo-gateway tetratelabs/gateway -n "${NAMESPACE}" \
#     --set global.tag=${TAG} \
#     --set global.hub="containers.istio.tetratelabs.com" \
#     --version ${VERSION}

# kubectl patch deployment -n "${NAMESPACE}" bookinfo-gateway --type='json' -p='[
#   {
#     "op": "add",
#     "path": "/spec/template/spec/containers/0/ports/-",
#     "value": {
#       "containerPort": 8080,
#       "protocol": "TCP"
#     }
#   },
#   {
#     "op": "add",
#     "path": "/spec/template/spec/containers/0/ports/-",
#     "value": {
#       "containerPort": 80,
#       "protocol": "TCP"
#     }
#   }
# ]'

# kubectl apply -n "${NAMESPACE}" -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/bookinfo/platform/kube/bookinfo.yaml

# kubectl apply -n "${NAMESPACE}" -f - <<EOF
# apiVersion: networking.istio.io/v1alpha3
# kind: Gateway
# metadata:
#   name: bookinfo-gateway
# spec:
#   # The selector matches the ingress gateway pod labels.
#   # If you installed Istio using Helm following the standard documentation, this would be "istio=ingress"
#   selector:
#     istio: bookinfo-gateway # use istio default controller
#   servers:
#     - port:
#         number: 80
#         name: http
#         protocol: HTTP
#       hosts:
#         - "bookinfo.tetrate.io"
# ---
# apiVersion: networking.istio.io/v1alpha3
# kind: VirtualService
# metadata:
#   name: bookinfo
# spec:
#   hosts:
#     - "bookinfo.tetrate.io"
#   gateways:
#     - bookinfo-gateway
#   http:
#     - match:
#         - uri:
#             exact: /productpage
#         - uri:
#             prefix: /static
#         - uri:
#             exact: /login
#         - uri:
#             exact: /logout
#         - uri:
#             prefix: /api/v1/products
#       route:
#         - destination:
#             host: productpage
#             port:
#               number: 9080
# EOF

# kubectl apply -n "${NAMESPACE}" -f - <<EOF
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: trafficgenerator
#   labels:
#     app: trafficgenerator
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: trafficgenerator
#   template:
#     metadata:
#       annotations:
#         sidecar.istio.io/inject: "false"
#       labels:
#         app: trafficgenerator
#     spec:
#       containers:
#         - name: trafficgenerator
#           image: appropriate/curl
#           args:
#             - /bin/sh
#             - -c
#             - |
#               while :; do
#                 # This trafficgenerator mimics external client requests.
#                 curl -H "Host: bookinfo.tetrate.io" http://bookinfo-gateway/productpage
#                 sleep 10
#               done
# ---
# apiVersion: v1
# kind: Service
# metadata:
#   name: trafficgenerator
#   labels:
#     app: trafficgenerator
# spec:
#   ports:
#     - port: 9080
#       name: http
#   selector:
#     app: trafficgenerator
# EOF

