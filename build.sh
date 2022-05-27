#!/bin/bash -ex

TARGET="${TARGET:-ipq40xx}"
IMAGE_NAME="openwrt-$TARGET"
CONFIG="configs/$TARGET.txt"
OPENWRT_VERSION="${OPENWRT_VERSION:-master}"
OPENWRT_BUILD_DATE="$(date '+%Y-%m-%d-%H-%M-%S')"

if [ ! -e "$CONFIG" ]
then
    echo "Invalid target $1: Config $CONFIG not found."
    exit 1
fi

function build_docker {
    docker rmi $IMAGE_NAME -f || true
    docker build \
        --progress plain \
        --build-arg OPENWRT_VERSION="$OPENWRT_VERSION" \
        --build-arg OPENWRT_BUILD_DATE="$OPENWRT_BUILD_DATE" \
        -t $IMAGE_NAME .
}

function run_in_docker {
    TARGET_DIR="build/$TARGET"
    mkdir -p downloads
    mkdir -p $TARGET_DIR
    docker rm $IMAGE_NAME -f || true
    time docker run -it --rm \
        --name $IMAGE_NAME \
        -v $PWD/$TARGET_DIR:/build \
        -v $PWD/configs/common.txt:/root/openwrt/.config-common \
        -v $PWD/$CONFIG:/root/openwrt/.config-template \
        -v $PWD/downloads:/root/openwrt/dl/ \
        -v $PWD/files:/root/openwrt/files/ \
        -v $PWD/docker-scripts:/root/openwrt/docker-scripts \
        $IMAGE_NAME \
        ./docker-scripts/$1.sh
}

if [ "$1" = "" ]
then
    echo "Usage: $0 (config|docker|firmware)+"
    echo "See https://github.com/rusitschka/openwrt-mikrotik-hap-ac2/blob/main/README.md"
    exit 1
fi

while [ "$1" != "" ]
do
    case "$1" in
        firmware)
            run_in_docker "firmware"
            ;;
        config)
            run_in_docker "config"
            ;;
        docker)
            build_docker
            ;;
        *)
            echo "Unsupported command: $1"
            exit 1
            ;;
    esac
    shift
done
