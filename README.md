# openwrt-mikrotik

This script builds OpenWRT via Docker images/containers, i.e. Docker is your only build dependency.

Tested versions of OpenWRT:

* 23.05.0

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

To build the master branch of OpenWRT use:

```bash
OPENWRT_VERSION=master ./build.sh
```

To build a tagged 23.05.0 OpenWRT version which supports hAP ac2 and cAP ac use for example:

```bash
OPENWRT_VERSION=v23.05.0 ./build.sh
```

To build a branch, use the branch name, e.g.:

```bash
OPENWRT_VERSION=openwrt-23.05 ./build.sh
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
