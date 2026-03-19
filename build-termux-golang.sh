
#! /bin/bash

set -e

WORKSPACE=/tmp/workspace
mkdir -p $WORKSPACE
mkdir -p /work/artifact

cd / && curl -LO https://dl.google.com/android/repository/android-ndk-r29-linux.zip && unzip android-ndk-r29-linux.zip
export CC="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android23-clang"

# iNetspeed
cd $WORKSPACE
git clone https://github.com/tsosunchia/iNetSpeed-CLI
cd iNetSpeed-CLI
VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null || echo "dev")}" && \
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")" && \
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LDFLAGS="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}"
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -pgo=auto -a -ldflags "${LDFLAGS}" -o ./speedtest ./cmd/speedtest

tar vcJf ./speedtest.tar.xz speedtest
cp ./speedtest.tar.xz /work/artifact

# rclone
cd $WORKSPACE
git clone https://github.com/rclone/rclone
cd rclone
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -pgo=auto -a -ldflags '-w -s'

tar vcJf ./rclone.tar.xz rclone
cp ./rclone.tar.xz /work/artifact
