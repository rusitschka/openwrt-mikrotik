#!/bin/bash -ex

git config --global init.defaultBranch main
git config --global user.email "noreply@example.com"
git config --global user.name "No Name"

if [ -d .git ]
then
    git reset --hard
    git fetch --all
else
    git init .
    git remote add -t \* -f origin https://github.com/openwrt/openwrt.git
fi

[ -e version ] && rm version
git checkout $OPENWRT_VERSION
git reset --hard
git am --abort 2>/dev/null || true

PATCHES=(
    "https://github.com/openwrt/openwrt/pull/23181.patch"
)

echo "$OPENWRT_BUILD_DATE" > version
for PATCH in "${PATCHES[@]}"
do
    [ -n "$PATCH" ] || continue
    wget -O /tmp/openwrt.patch "$PATCH"
    git am --3way /tmp/openwrt.patch
    rm /tmp/openwrt.patch
    echo "Patched $PATCH"
done

./scripts/feeds update -a
./scripts/feeds install -a

cat .config-template .config-common > .config
make defconfig

# delete all downloaded files older than 7 days
[ -d dl ] && find dl/ -type f -mtime +7 -delete

exec "$@"
