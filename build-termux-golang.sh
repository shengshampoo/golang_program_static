
#! /bin/bash

set -e

WORKSPACE=/tmp/workspace
mkdir -p $WORKSPACE
mkdir -p /work/artifact

curl -LO https://dl.google.com/android/repository/android-ndk-r29-linux.zip && unzip android-ndk-r29-linux.zip

mv /usr/bin/cc /usr/bin/cc.old
ln -sf /android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/clang /usr/bin/cc
export CC="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android23-clang"
export CXX="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android23-clang++"
export AR="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export AS=$CC
export LD="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/ld"
export RANLIB="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
export STRIP="/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
export PATH=/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/:$PATH
export ANDROID_NDK_HOME="/android-ndk-r29"
export ANDROID_NDK="/android-ndk-r29"
export ANDROID_NDK_ROOT="/android-ndk-r29"

# iNetspeed
cd $WORKSPACE
git clone https://github.com/tsosunchia/iNetSpeed-CLI
cd iNetSpeed-CLI
VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null || echo "dev")}" && \
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")" && \
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LDFLAGS="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}"
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -pgo=auto -a -ldflags "${LDFLAGS}" -o ./inetspeed ./cmd/speedtest

tar vcJf ./inetspeed.tar.xz inetspeed
cp ./inetspeed.tar.xz /work/artifact

# NTrace-core
cd $WORKSPACE
git clone https://github.com/nxtrace/NTrace-core
cd NTrace-core
VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null || echo "dev")}" && \
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")" && \
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LDFLAGS="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}"
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -trimpath -pgo=auto -a -ldflags "${LDFLAGS}" -o ./nexttrace .

tar vcJf ./nexttrace.tar.xz nexttrace
cp ./nexttrace.tar.xz /work/artifact

# rclone
cd $WORKSPACE
git clone https://github.com/rclone/rclone
cd rclone
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -pgo=auto -a -ldflags '-w -s'

tar vcJf ./rclone.tar.xz rclone
cp ./rclone.tar.xz /work/artifact

# q
cd $WORKSPACE
git clone https://github.com/natesales/q
cd q
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -pgo=auto -a -ldflags '-w -s -X main.version=release'

tar vcJf ./q.tar.xz q
cp ./q.tar.xz /work/artifact

# doggo
cd $WORKSPACE
git clone https://github.com/mr-karan/doggo
cd doggo
HASH="$(git rev-parse --short HEAD)"
BUILD_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
VERSION=$HASH
CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -pgo=auto -a -ldflags="-w -s -X 'main.buildVersion=${VERSION}' -X 'main.buildDate=${BUILD_DATE}'" -o ./doggo ./cmd/doggo/

tar vcJf ./doggo.tar.xz doggo
cp ./doggo.tar.xz /work/artifact
