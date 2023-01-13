#!/bin/bash -ex

DEFAULT_OPENWRT_VERSION="v22.03.3"
#DEFAULT_OPENWRT_VERSION="openwrt-22.03"
#DEFAULT_OPENWRT_VERSION="master"

TARGET="${TARGET:-ipq40xx}"
IMAGE_NAME="openwrt-mikrotik"
CONFIG="configs/$TARGET.txt"
OPENWRT_VERSION="${OPENWRT_VERSION:-${DEFAULT_OPENWRT_VERSION}}"
OPENWRT_BUILD_DATE="$(date '+%Y-%m-%d-%H-%M-%S')"

if [ ! -e "$CONFIG" ]
then
    echo "Invalid target $1: Config $CONFIG not found."
    exit 1
fi

function build_docker {
    docker rmi $IMAGE_NAME.build -f || true
    docker build \
        --progress plain \
        -t $IMAGE_NAME.build .
    docker rmi $IMAGE_NAME -f || true
    docker tag $IMAGE_NAME.build $IMAGE_NAME
    docker rmi $IMAGE_NAME.build -f || true
}

function run_in_docker {
    TARGET_DIR="build/$TARGET"
    mkdir -p downloads
    mkdir -p $TARGET_DIR
    docker volume create $IMAGE_NAME-root-openwrt || true
    docker rm $IMAGE_NAME -f || true
    time docker run -it --rm \
        --name $IMAGE_NAME \
        -e OPENWRT_VERSION=$OPENWRT_VERSION \
        -e OPENWRT_BUILD_DATE=$OPENWRT_BUILD_DATE \
        -v $IMAGE_NAME-root-openwrt:/root/openwrt/ \
        -v $PWD/$TARGET_DIR:/build \
        -v $PWD/configs/common.txt:/root/openwrt/.config-common \
        -v $PWD/$CONFIG:/root/openwrt/.config-template \
        -v $PWD/files:/root/openwrt/files/ \
        -v $PWD/docker-scripts:/root/openwrt/docker-scripts \
        $IMAGE_NAME \
        ./docker-scripts/$1.sh
}

if [ "$1" = "" ]
then
    set +x
    echo
    echo "Usage: $0 (config|docker|firmware)+"
    echo "See https://github.com/rusitschka/openwrt-mikrotik/blob/main/README.md"
    exit 1
fi

while [ "$1" != "" ]
do
    case "$1" in
        clean)
            docker rm $IMAGE_NAME || true
            docker rmi $IMAGE_NAME || true
            docker volume rm $IMAGE_NAME-root-openwrt || true
            ;;
        config)
            run_in_docker "config"
            ;;
        docker)
            build_docker
            ;;
        firmware)
            run_in_docker "firmware"
            ;;
        shell)
            run_in_docker "shell"
            ;;
        *)
            echo "Unsupported command: $1"
            exit 1
            ;;
    esac
    shift
done
