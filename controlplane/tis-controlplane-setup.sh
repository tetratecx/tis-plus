#!/usr/bin/env bash

set -x

SCRIPTPATH=$(dirname "$0")
# Execute this file on terminal with command -
# CLUSTER="test-cluster" HUB='docker.io/imnizam' MP_HOST="hosted-mp.tetrate.io"  IMAGE_PULL_SECRET=''  ./controlplane/tis-controlplane-setup.sh

export CLUSTER="${CLUSTER:-"app-cluster"}" # For TIS+ cluster object creation, Refer ./onboard-tis-controlplane.sh

export HUB="${HUB:-"123456789.dkr.ecr.us-east-2.amazonaws.com/tis-plus"}"
export MP_HOST="${MP_HOST:-"fe546279.aws.tsb.tetrate.com"}"
export IMAGE_PULL_SECRET="${IMAGE_PULL_SECRET:-""}"
export RELEASE_NAME="${RELEASE_NAME:-"tis-plus-cp"}"
export NAMESPACE="${NAMESPACE:-"tis-plus-system"}"
export VERSION=${VERSION:-"1.11.1"}
export HELM_PKG=${HELM_PKG:-"tetrate-tsb-helm/controlplane"}


# check for image pull secrets for local docker hub
# doc : https://docs.tetrate.io/istio-subscription-plus/installation/pre-checks#set-up-pull-secrets-in-the-tis-plus-namespace

if [[ -n "$IMAGE_PULL_SECRET" ]];then
  kubectl -n $NAMESPACE get secrets $IMAGE_PULL_SECRET
  if [[ $? != 0 ]];then
    echo -e "Checking for imagePullSecrets to access container registry .... \n Please create imagePullSecrets in $NAMESPACE namepsace.."
    exit 1
  fi
fi

echo "Installing controlplane... "
# doc : https://docs.tetrate.io/istio-subscription-plus/installation/onboard-cluster

helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update

helm upgrade --install "${RELEASE_NAME}" "${HELM_PKG}" \
  --version $VERSION \
  --namespace tis-plus-system --create-namespace \
  -f "${SCRIPTPATH}/${CLUSTER}-values.yaml" \
  -f "${SCRIPTPATH}/oap-patch.yaml" \
  --set image.registry="${HUB}" \
  --set image.tag="${VERSION}" \
  --set spec.hub="${HUB}" \
  --set spec.mode="OBSERVE" \
  --set operator.controlPlaneMode="OBSERVE" \
  --set operator.deletionProtection="disabled" \
  --set spec.managementPlane.host="$MP_HOST" \
  --set spec.telemetryStore.elastic.host="$MP_HOST" \
  --set spec.imagePullSecrets[0].name="$PULL_SECRET" \
  --set operator.serviceAccount.imagePullSecrets[0]="$PULL_SECRET"