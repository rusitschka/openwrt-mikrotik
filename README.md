# openwrt-mikrotik-hap-ac2

This script will patch current
[21.02 branch of OpenWRT](https://github.com/openwrt/openwrt/tree/openwrt-21.02) with
[Mikrotik hAP ac2 PR 3073](https://github.com/openwrt/openwrt/pull/3037),
[Mikrotik cAP ac PR 4055](https://github.com/openwrt/openwrt/pull/4055), and
[Mikrotik hAP ac lite PR 3348](https://github.com/openwrt/openwrt/pull/3348).

It's all done through Docker images/containers so you need to
have Docker installed.

To build OpenWRT for Mikrotik hAP ac2 execute:
```
./build.sh hap-ac2
```

For Mikrotik cAP ac execute:
```
./build.sh cap-ac
```

And for Mikrotik hAP ac lite: **This currently does not work due to a missing [upstream fix](https://github.com/openwrt/openwrt/pull/3348#issuecomment-692530450)!**
```
./build.sh hap-ac-lite
```

After the script finishes the resulting target builds are
copied from the Docker image to the `build` folder in the local
file system. The resulting Docker images/containers will be up to
12G each in size and can be deleted after the build finished.

The whole process takes about 45 minutes on a modern CPU.
