# Sync Tetrate provided controlplane images to client managed docker repo
# Client managed docker repo - "The destination" 
DEST_REG=gcr.io/xcp-istio

# Tetrate shared docker repo - "The source"
SOURCE_REG=docker.io/imnizam

# Docker image copying tool is required, that can pull from source repo and push it to the destination registry.
# Here, we are using skopeo for the same purpose.
# Install skopeo - https://github.com/containers/skopeo/blob/main/install.md

##########
# List of images to be copied images
#########
# xcpd:6a873619d5ddd38c93186fc9099684af5fbdb5c5
# spm-user:3f876e35d17206ab5e3497c9c6e4639b78cdf08b
# proxyv2:1.21.4-9adece3cec-distroless
# otelcol:0.105.0
# tsboperator-server:26e7773a9e6c872cb418a38a209740f2be892456
# xcp-operator:6a873619d5ddd38c93186fc9099684af5fbdb5c5

#1
IMG="xcpd:6a873619d5ddd38c93186fc9099684af5fbdb5c5"
skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
#2
IMG="spm-user:3f876e35d17206ab5e3497c9c6e4639b78cdf08b"
skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
#3
IMG="proxyv2:1.21.4-9adece3cec-distroless"
skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
#4
IMG="otelcol:0.105.0"
skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
#5
IMG="tsboperator-server:26e7773a9e6c872cb418a38a209740f2be892456"
skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
#6
IMG="xcp-operator:6a873619d5ddd38c93186fc9099684af5fbdb5c5"
skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}


