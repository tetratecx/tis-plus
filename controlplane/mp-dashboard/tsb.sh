#!/usr/bin/env bash

set -x

#command

#MP_HOST="hosted-mp.tetrate.io" MP_PASSWORD='mp_password' TCTL="./tctl-bin/tctl-amd64" ./controlplane/tsb/tsb.sh

# tctl login 
MP_HOST="${MP_HOST:-"hosted-mp.tetrate.io"}"
MP_PASSWORD="${MP_PASSWORD:-""}"
ORG="tetrate"
tctl="${TCTL:-"tctl"}"

$tctl config clusters set my-management-plane --bridge-address ${MP_HOST}:443 --tls-insecure
$tctl config profiles set my-management-plane --cluster my-management-plane
$tctl config profiles set-current my-management-plane

TCTL_LOGIN_ORG="${ORG}" TCTL_LOGIN_TENANT="" TCTL_LOGIN_USERNAME=admin TCTL_LOGIN_PASSWORD=${MP_PASSWORD} $tctl login


# create cluster in TSB
cat << EOF | $tctl apply -f -
---
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate
  name: tetrate
spec:
  displayName: tetrate
---
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "cluster-name/app-namespace1"
      - "cluster-name/app-namespace2"
      - "cluster-name2/app-namespace1"
EOF