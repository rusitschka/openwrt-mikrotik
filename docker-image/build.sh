#!/bin/bash -ex

cp .config-template .config
export FORCE_UNSAFE_CONFIGURE=1
make defconfig
# 10 parallel downloads no matter how many actual CPU cores
make -j10 download
if ! make -j$(nproc) world
then
    make V=sc world
fi
cp -a bin/targets/* /build/
