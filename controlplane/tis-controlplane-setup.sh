#!/usr/bin/env bash

set -x
# command
# CLUSTER="test-cluster" HUB='docker.io/imnizam' MP_HOST="hosted-mp.tetrate.io"   ./controlplane/tis-controlplane-setup.sh

CLUSTER="${CLUSTER:-"app-cluster"}"
HUB="${HUB:-"docker.io/imnizam"}"
MP_HOST="${MP_HOST:-"hosted-mp.aws-ce.sandbox.tetrate.io"}"
IMAGE_PULL_SECRET="${IMAGE_PULL_SECRET:-''}"
RELEASE_NAME="${RELEASE_NAME:-"tis-plus-cp"}"
NAMESPACE="${NAMESPACE:-"tis-plus-system"}"
TAG=${TAG:-"26e7773a9e6c872cb418a38a209740f2be892456"}
HELM_PKG=${HELM_PKG:-"./controlplane/controlplane-1.10.0-dev+26e7773a9.tgz"}

helm upgrade --install "${RELEASE_NAME}" "${HELM_PKG}" \
  --namespace "${NAMESPACE}" --create-namespace \
  -f "${CLUSTER}-values.yaml" \
  --set image.registry="${HUB}" \
  --set image.tag="${TAG}" \
  --set spec.hub="${HUB}" \
  --set spec.mode="OBSERVE" \
  --set operator.enableObserveMode=true \
  --set operator.deletionProtection="disabled" \
  --set spec.imagePullSecrets[0].name="${IMAGE_PULL_SECRET}"
