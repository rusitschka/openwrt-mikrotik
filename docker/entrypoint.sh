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
    "https://github.com/openwrt/openwrt/pull/26652.patch"
)

echo "$OPENWRT_BUILD_DATE" > version
for PATCH in "${PATCHES[@]}"
do
    [ -n "$PATCH" ] || continue
    wget -O /tmp/openwrt.patch "$PATCH"
    PATCH_BASE=$(git rev-parse HEAD)
    git am --3way /tmp/openwrt.patch
    rm /tmp/openwrt.patch

    # OpenWrt 25.12's hostapd predates EPP support. Only adapt this PR's files.
    if [ "$PATCH" = "https://github.com/openwrt/openwrt/pull/26652.patch" ] &&
        grep -qx 'PKG_SOURCE_DATE:=2025-08-26' package/network/services/hostapd/Makefile
    then
        HOSTAPD_PATCHES=$(git diff --name-only --no-renames --diff-filter=AM \
            "$PATCH_BASE" HEAD -- package/network/services/hostapd/patches/)
        while IFS= read -r HOSTAPD_PATCH
        do
            [ -n "$HOSTAPD_PATCH" ] || continue
            if grep -qF 'ap_sta_is_epp(' "$HOSTAPD_PATCH"
            then
                sed -i 's/ && !ap_sta_is_epp(sta)//' "$HOSTAPD_PATCH"
                if grep -qF 'ap_sta_is_epp(' "$HOSTAPD_PATCH"
                then
                    echo "Unsupported EPP condition in $HOSTAPD_PATCH; review PR #26652's backport." >&2
                    exit 1
                fi
            fi
        done <<< "$HOSTAPD_PATCHES"
    fi
    echo "Patched $PATCH"
done

./scripts/feeds update -a
./scripts/feeds install -a

cat .config-template .config-common > .config
make defconfig

# delete all downloaded files older than 7 days
[ -d dl ] && find dl/ -type f -mtime +7 -delete

exec "$@"
