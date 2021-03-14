#!/bin/bash -ex

TARGET="$1"
IMAGE_NAME="openwrt-$TARGET"
CONFIG="configs/$TARGET.txt"

if [ ! -e "$CONFIG" ]
then
    echo "Invalid target $1: Config $CONFIG not found."
    exit 1
fi

docker rm $IMAGE_NAME -f || true
docker rmi $IMAGE_NAME -f || true
docker build -t $IMAGE_NAME .
TARGET_DIR="build/$TARGET/$(date +'%Y%m%d.%H%M')"
mkdir -p downloads
mkdir -p $TARGET_DIR
docker run -it \
    --name $IMAGE_NAME \
    -v $PWD/$TARGET_DIR:/build \
    -v $PWD/downloads:/root/openwrt/dl/ \
    -v $PWD/$CONFIG:/root/openwrt/.config-template \
    $IMAGE_NAME \
    ./build.sh
docker rm $IMAGE_NAME
