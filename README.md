# openwrt-mikrotik

This script builds OpenWRT via Docker images/containers, i.e. Docker is your only build dependency.

Supported versions of OpenWRT:

* Current [master branch](https://github.com/openwrt/openwrt/tree/master) without any patches.
* 21.02.x version without any patches.

## Configuring
The default target is ipq40xx for Mikrotik hAP ac2 and cAP ac.

You can add new targets by creating files in configs, similar to ipq40xx. A config will get merged
with common.txt which basically contains all the packages you'd like to have in the image.

To create new configs use
```
./build.sh docker config
```
which runs OpenWRTs menuconfig. Use the resulting
output to create new config files with the name of your choice.

## Building firmware images

To build OpenWRT execute:
```
./build.sh docker firmware
```

The default target is `ipq40xx`. If you'd like to use a different target run the script like this:
```
TARGET=hap-ac2 ./build.sh docker firmware
```
This will use `configs/hap-ac2.txt` as config.

To build a tagged 21.02.x OpenWRT version which supports hAP ac2 and cAP ac use for example:
```
OPENWRT_VERSION=v21.02.1 ./build.sh docker firmware
```

To build a branch, use the branch name, e.g.:
```
OPENWRT_VERSION=openwrt-21.02 ./build.sh docker firmware
```

After the script finishes the resulting target builds are
copied from the Docker container to the `build` folder in the local
file system. The resulting Docker images/containers will be up to
12G each in size and can be deleted after the build finished.

The whole process takes about 45 minutes on a modern CPU.
