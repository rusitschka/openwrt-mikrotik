#!/bin/bash -ex

TARGET="$1"
IMAGE_NAME="openwrt-$TARGET"
CONFIG="config-$TARGET.txt"

if [ ! -e "$CONFIG" ]
then
    echo "Invalid target $1: Config $CONFIG not found."
    exit 1
fi

docker rmi $IMAGE_NAME -f || true
docker build --build-arg CONFIG=$CONFIG -t $IMAGE_NAME .
TARGET_DIR="build/$TARGET/$(date +'%Y%m%d.%H%M')"
mkdir -p $TARGET_DIR
docker run --rm -v $PWD/$TARGET_DIR:/build $IMAGE_NAME bash -c "[ -e error.log ] && cat error.log || cp -a /root/openwrt/bin/targets/* /build/"
