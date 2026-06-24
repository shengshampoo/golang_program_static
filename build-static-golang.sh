
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
CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" make

cd local
tar vcJf ./graftcp.tar.xz graftcp
cp ./graftcp.tar.xz /work/artifact

