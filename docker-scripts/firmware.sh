#!/bin/bash -ex

# delete all downloaded files older than 3 days
find dl/ -type f -mtime +3 -delete

# 10 parallel downloads no matter how many actual CPU cores
make -j10 download
if ! make -j2 world
then
    make V=sc world
fi

TARGET_DIR="/build/${OPENWRT_BUILD_DATE}_${OPENWRT_VERSION}"
mkdir -p "$TARGET_DIR"
cp -a bin/targets/* "$TARGET_DIR"
