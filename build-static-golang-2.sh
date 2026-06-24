
#! /bin/bash

set -e

WORKSPACE=/tmp/workspace
mkdir -p $WORKSPACE
mkdir -p /work/artifact

# gotify
cd $WORKSPACE
git clone https://github.com/gotify/server
cd ./server/ui
npm install . --force
yarn build && cd ../
export LD_FLAGS="-w -s -X main.Version=$(git describe --tags | cut -c 2-) -X main.BuildDate=$(date "+%F-%T") -X main.Commit=$(git rev-parse --verify HEAD) -X main.Mode=prod"
if [ "$(uname -m)" == "x86_64" ]; then
CGO_ENABLED=1 GOAMD64=v3 GOOS=$(uname -o | sed -e s@^.*/@@ | tr '[:upper:]' '[:lower:]') GOARCH=amd64 go build -pgo=auto -a -tags netgo -ldflags="$LD_FLAGS -w -s -extldflags '-static'" -o gotify-server
elif [ "$(uname -m)" == "aarch64" ]; then
CGO_ENABLED=1 GOARM64=v8.0,lse GOOS=$(uname -o | sed -e s@^.*/@@ | tr '[:upper:]' '[:lower:]') GOARCH=arm64 go build -pgo=auto -a -tags netgo -ldflags="$LD_FLAGS -w -s -extldflags '-static'" -o gotify-server
else
exit 1
fi

tar vcJf ./gotify-server.tar.xz gotify-server
cp ./gotify-server.tar.xz /work/artifact
