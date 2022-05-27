#!/bin/bash -ex

echo "$OPENWRT_BUILD_DATE" > version
cat .config-template .config-common > .config
export FORCE_UNSAFE_CONFIGURE=1
make defconfig

exec "$@"
