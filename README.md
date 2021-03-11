# openwrt-mikrotik-hap-ac2

This script will patch current [21.02 branch of OpenWRT](https://github.com/openwrt/openwrt/tree/openwrt-21.02)
with [Mikrotik hAP ac2 PR 3073](https://github.com/openwrt/openwrt/pull/3037).

It's all done inside a Docker image build so you need to
have Docker installed.

After the script finishes the resulting target builds are
copied from the Docker image to the `build` folder in the local
file system.

The whole process takes more than 2h on a modern CPU.
`make` is not run in parallel due to build stability.
