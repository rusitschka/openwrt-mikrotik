#!/bin/bash -ex

TARGET="hap-ac2"
IMAGE_NAME="openwrt-$TARGET"
CONFIG="configs/$TARGET.txt"
OPENWRT_VERSION="master"
OPENWRT_BUILD_DATE="$(date '+%Y-%m-%d-%H-%M-%S')"

if [ ! -e "$CONFIG" ]
then
    echo "Invalid target $1: Config $CONFIG not found."
    exit 1
fi

docker rm $IMAGE_NAME -f || true
docker rmi $IMAGE_NAME -f || true
docker build \
    --build-arg OPENWRT_VERSION="$OPENWRT_VERSION" \
    --build-arg OPENWRT_BUILD_DATE="$OPENWRT_BUILD_DATE" \
    -t $IMAGE_NAME .

if [ "$2" = "--docker-only" ]
then
  exit
fi

TARGET_DIR="build/$TARGET"
mkdir -p downloads
mkdir -p $TARGET_DIR
docker run -it \
    --name $IMAGE_NAME \
    -v $PWD/$TARGET_DIR:/build \
    -v $PWD/downloads:/root/openwrt/dl/ \
    -v $PWD/files:/root/openwrt/files/ \
    -v $PWD/$CONFIG:/root/openwrt/.config-template \
    $IMAGE_NAME \
    ./build.sh
docker rm $IMAGE_NAME
