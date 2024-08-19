#!/usr/bin/env bash

set -x

# command
# MP_HOST="hosted-mp.tetrate.io" MP_PASSWORD='mp_password' TCTL="./tctl-bin/tctl-amd64" CLUSTER="test-cluster" ./controlplane/onboard-tis-controlplane.sh

# tctl login 
MP_HOST="${MP_HOST:-"hosted-mp.tetrate.io"}"
MP_PASSWORD="${MP_PASSWORD:-""}"
tctl="${TCTL:-"tctl"}"
$tctl config clusters set my-management-plane --bridge-address ${MP_HOST}:443 --tls-insecure
$tctl config profiles set my-management-plane --cluster my-management-plane
$tctl config profiles set-current my-management-plane

TCTL_LOGIN_ORG=tetrate TCTL_LOGIN_TENANT="" TCTL_LOGIN_USERNAME=admin TCTL_LOGIN_PASSWORD=${MP_PASSWORD} $tctl login


CLUSTER="${CLUSTER:-"app-cluster"}"

ORG="tetrate"
# create cluster in TSB
cat << EOF | $tctl apply -f -
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  displayName: $CLUSTER
  name: $CLUSTER
  organization: $ORG
spec:
  displayName: $CLUSTER
  tokenTtl: "8760h"
EOF

$tctl x cluster-install-template "${CLUSTER}" > "${CLUSTER}-values.yaml"
