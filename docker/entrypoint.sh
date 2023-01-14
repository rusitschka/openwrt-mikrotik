#!/bin/bash -ex

if [ -d .git ]
then
    git reset --hard
    git fetch --all
else
    git config --global init.defaultBranch main
    git config --global user.email "noreply@example.com"
    git config --global user.name "No Name"
    git init .
    git remote add -t \* -f origin https://github.com/openwrt/openwrt.git
fi

[ -e version ] && rm version
git checkout $OPENWRT_VERSION
git reset --hard
echo "$OPENWRT_BUILD_DATE" > version

./scripts/feeds update -a
./scripts/feeds install -a

cat .config-template .config-common > .config
make defconfig

# delete all downloaded files older than 7 days
[ -d dl ] && find dl/ -type f -mtime +7 -delete

exec "$@"
