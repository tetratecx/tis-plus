#!/usr/bin/env bash

set -x
# command
# CLUSTER="test-cluster" HUB='docker.io/imnizam' MP_HOST="hosted-mp.tetrate.io"  IMAGE_PULL_SECRET=''  ./controlplane/tis-controlplane-setup.sh

CLUSTER="${CLUSTER:-"app-cluster"}"
HUB="${HUB:-"docker.io/imnizam"}"
MP_HOST="${MP_HOST:-"hosted-mp.aws-ce.sandbox.tetrate.io"}"
IMAGE_PULL_SECRET="${IMAGE_PULL_SECRET:-""}"
RELEASE_NAME="${RELEASE_NAME:-"tis-plus-cp"}"
NAMESPACE="${NAMESPACE:-"tis-plus-system"}"
TAG=${TAG:-"26e7773a9e6c872cb418a38a209740f2be892456"}
HELM_PKG=${HELM_PKG:-"./controlplane/controlplane-1.10.0-dev+26e7773a9.tgz"}

if [[ -n "$IMAGE_PULL_SECRET" ]];then
  kubectl -n $NAMESPACE get secrets $IMAGE_PULL_SECRET
  if [[ $? != 0 ]];then
    echo -e "Checking for imagePullSecrets to access container registry .... \n Please create imagePullSecrets in $NAMESPACE namepsace.."
    exit 1
  fi
fi
echo "Installing controlplane... "

helm upgrade --install "${RELEASE_NAME}" "${HELM_PKG}" \
  --namespace "${NAMESPACE}" --create-namespace \
  -f "${CLUSTER}-values.yaml" \
  -f ./controlplane/oap-patch.yaml \
  --set image.registry="${HUB}" \
  --set image.tag="${TAG}" \
  --set spec.hub="${HUB}" \
  --set spec.mode="OBSERVE" \
  --set operator.enableObserveMode=true \
  --set operator.deletionProtection="disabled" \
  --set spec.imagePullSecrets[0].name="${IMAGE_PULL_SECRET}" \
  --set operator.serviceAccount.imagePullSecrets[0]="${IMAGE_PULL_SECRET}"



# kubectl patch serviceaccount tsb-operator-control-plane -p '{"imagePullSecrets": [{"name": "${IMAGE_PULL_SECRET}"}]}' -n "${NAMESPACE}"
# kubectl delete pod  -n "${NAMESPACE}" -l=name=tsb-operator
