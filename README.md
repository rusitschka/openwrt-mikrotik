# openwrt-mikrotik

This script builds OpenWRT via Docker images/containers, i.e. Docker is your only build dependency.

Tested versions of OpenWRT:

* 24.10.0

## Configuring

The default target is ipq40xx for Mikrotik hAP ac2 and cAP ac.

You can add new targets by creating files in configs, similar to ipq40xx. A config will get merged
with common.txt which basically contains all the packages you'd like to have in the image.

To create new configs use

```bash
./build.sh docker config
```

which runs OpenWRTs menuconfig. Use the resulting
output to create new config files with the name of your choice.

## Building firmware images

To build OpenWRT execute:

```bash
./build.sh
```

The default target is `ipq40xx`. If you'd like to use a different target run the script like this:

```bash
TARGET=ath79 ./build.sh
```

This will use `configs/ath79.txt` as config.

You can also build multiple targets at the same time:

```bash
TARGET=ipq40xx,ath79,rtl838x ./build.sh
```


To build the master branch of OpenWRT use:

```bash
OPENWRT_VERSION=master ./build.sh
```

To build a tagged 24.10.0 OpenWRT version which supports hAP ac2 and cAP ac use for example:

```bash
OPENWRT_VERSION=v24.10.0 ./build.sh
```

To build a branch, use the branch name, e.g.:

```bash
OPENWRT_VERSION=openwrt-24.10 ./build.sh
```

After the script finishes the resulting target builds are
copied from the Docker container to the `build` folder in the local
file system. The resulting Docker images/containers will be up to
12G each in size and can be deleted after the build finished.

The whole process takes about 45 minutes on a modern CPU.

To clean the build files and force a fresh next build execute:

```bash
./build.sh clean
```

To get shell access to the build environment (useful for debugging):

```bash
./build.sh shell
```

## ath10k AQL mitigation

The image includes a test mitigation for ath10k Wi-Fi stalls where the kernel logs
`ath10k... failed to lookup txq` and clients disconnect or stall. This matches
[OpenWrt issue #9455](https://github.com/openwrt/openwrt/issues/9455), where
disabling AQL through debugfs is reported as a workaround.

At boot, `/etc/init.d/ath10k-aql-disable` tries to disable AQL on all radios:

```sh
for aql in /sys/kernel/debug/ieee80211/phy*/aql_enable; do
    [ -e "$aql" ] && echo 0 > "$aql"
done
```

Treat this as a test mitigation. Monitor whether `ath10k` txq lookup errors,
Wi-Fi stalls, and client disconnect counts drop after deploying the image.
