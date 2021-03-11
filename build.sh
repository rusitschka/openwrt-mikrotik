#!/bin/bash -ex

IMAGE_NAME=openwrt-mikrotik-hap-ac2
docker rmi $IMAGE_NAME -f || true
docker build -t $IMAGE_NAME .
mkdir -p build
rm -rf build/*
docker run --rm -v $PWD/build:/build $IMAGE_NAME bash -c "cp -a /root/openwrt/bin/targets/* /build/"
