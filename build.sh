#!/bin/bash -ex

TARGET="$1"
IMAGE_NAME="openwrt-$TARGET"
CONFIG="configs/$TARGET.txt"
OPENWRT_VERSION="21.02.0"
OPENWRT_BUILD_DATE="$(date '+%Y-%m-%d-%H-%M-%S')"

if [ "$TARGET" = "hap-ac2" ]
then
    echo "Downloading and patching hAP ac2 config"
    curl -sfq https://downloads.openwrt.org/releases/$OPENWRT_VERSION/targets/ipq40xx/mikrotik/config.buildinfo \
        > $CONFIG
    cat configs/common.txt >> $CONFIG
fi

if [ ! -e "$CONFIG" ]
then
    echo "Invalid target $1: Config $CONFIG not found."
    exit 1
fi

docker rm $IMAGE_NAME -f || true
docker rmi $IMAGE_NAME -f || true
docker build --no-cache -t $IMAGE_NAME .

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
    ./build.sh "$OPENWRT_VERSION" "$OPENWRT_BUILD_DATE"
docker rm $IMAGE_NAME
