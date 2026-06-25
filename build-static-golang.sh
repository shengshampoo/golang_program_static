
#! /bin/bash

set -e

WORKSPACE=/tmp/workspace
mkdir -p $WORKSPACE
mkdir -p /work/artifact

# rclone
cd $WORKSPACE
git clone https://github.com/rclone/rclone
cd rclone
if [ "$(uname -m)" == "x86_64" ]; then
GOAMD64=v3 GOOS=$(uname -o | sed -e s@^.*/@@ | tr '[:upper:]' '[:lower:]') GOARCH=amd64 CGO_ENABLED=0 go build -pgo=auto -a -tags netgo -ldflags '-w -s -extldflags "-static"'
elif [ "$(uname -m)" == "aarch64" ]; then
GOARM64=v8.0,lse GOOS=$(uname -o | sed -e s@^.*/@@ | tr '[:upper:]' '[:lower:]') GOARCH=arm64 CGO_ENABLED=0 go build -pgo=auto -a -tags netgo -ldflags '-w -s -extldflags "-static"'
else
exit 1
fi

tar vcJf ./rclone.tar.xz rclone
cp ./rclone.tar.xz /work/artifact

# graftcp
cd $WORKSPACE
git clone https://github.com/hmgle/graftcp.git
cd graftcp
sed -i '/$(CROSS_COMPILE)/s/^/#&/' ./Makefile
sed -i '22i#define uint unsigned int' ./cidr-trie.c
sed -i '23i#define u_char unsigned char' ./cidr-trie.c 
sed -i '/^GO_LDFLAGS ?=/s/$/ -extldflags "-static"/' ./Makefile
sed -i '/^CFLAGS +=/s/$/ -static/' ./Makefile
CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" make

cd local
tar vcJf ./graftcp.tar.xz graftcp
cp ./graftcp.tar.xz /work/artifact

# gotify
npm install -g typescript
tsc -v
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
