# Sync Tetrate provided controlplane images to client managed docker repo

# download tctl doc: https://docs.tetrate.io/service-bridge/reference/cli/guide/index

#linux
mkdir -p ~/.tctl/bin
curl -Lo ~/.tctl/bin/tctl https://binaries.dl.tetrate.io/public/raw/versions/linux-$(uname -m | sed s/x86_64/amd64/)-1.11.1/tctl
chmod +x ~/.tctl/bin/tctl
export PATH=$PATH:~/.tctl/bin

#Mac
mkdir -p ~/.tctl/bin
curl -Lo ~/.tctl/bin/tctl https://binaries.dl.tetrate.io/public/raw/versions/darwin-$(uname -m | sed s/x86_64/amd64/)-1.11.1/tctl
chmod +x ~/.tctl/bin/tctl
sudo xattr -r -d com.apple.quarantine ~/.tctl/bin/tctl
export PATH=$PATH:~/.tctl/bin



# ecr image sync 
# doc : https://docs.tetrate.io/istio-subscription-plus/installation/tisplus-images

export HUB=123456789.dkr.ecr.ap-south-1.amazonaws.com/tis-plus
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${HUB}

tctl install image-sync \
  --accept-eula \
  --registry ${HUB} \
  --username <tetrate_provided> \
  --apikey <tetrate_provided>




# # sync images from one local source to other local source

# # Client managed docker repo - "The destination" 
# DEST_REG=gcr.io/xcp-istio

# # Tetrate shared docker repo - "The source"
# SOURCE_REG=docker.io/imnizam

# # Docker image copying tool is required, that can pull from source repo and push it to the destination registry.
# # Here, we are using skopeo for the same purpose.
# # Install skopeo - https://github.com/containers/skopeo/blob/main/install.md

# ##########
# # List of images to be copied images
# #########
# # xcpd:6a873619d5ddd38c93186fc9099684af5fbdb5c5
# # spm-user:3f876e35d17206ab5e3497c9c6e4639b78cdf08b
# # proxyv2:1.21.4-9adece3cec-distroless
# # otelcol:0.105.0
# # tsboperator-server:26e7773a9e6c872cb418a38a209740f2be892456
# # xcp-operator:6a873619d5ddd38c93186fc9099684af5fbdb5c5

# #1
# IMG="xcpd:6a873619d5ddd38c93186fc9099684af5fbdb5c5"
# skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
# #2
# IMG="spm-user:3f876e35d17206ab5e3497c9c6e4639b78cdf08b"
# skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
# #3
# IMG="proxyv2:1.21.4-9adece3cec-distroless"
# skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
# #4
# IMG="otelcol:0.105.0"
# skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
# #5
# IMG="tsboperator-server:26e7773a9e6c872cb418a38a209740f2be892456"
# skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}
# #6
# IMG="xcp-operator:6a873619d5ddd38c93186fc9099684af5fbdb5c5"
# skopeo copy --all docker://${SOURCE_REG}/${IMG} docker://${DEST_REG}/${IMG}


