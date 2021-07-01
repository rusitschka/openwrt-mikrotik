# openwrt-mikrotik-hap-ac2

This script will patch current
[21.02 branch of OpenWRT](https://github.com/openwrt/openwrt/tree/openwrt-21.02) with
[Mikrotik cAP ac from vibornoff](https://github.com/vibornoff/openwrt/tree/mikrotik-cap-ac-wip).

It's all done through Docker images/containers so you need to
have Docker installed.

OpenWRT 21.02 already comes with hAP ac2 support built-in. The name of this project has
historic reasons. When I started this project hAP ac2 support had to patched into official
OpenWRT source. Nowadays cAP ac support is still missing from 21.02 which still requires a
patch.

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
copied from the Docker container to the `build` folder in the local
file system. The resulting Docker images/containers will be up to
12G each in size and can be deleted after the build finished.

The whole process takes about 45 minutes on a modern CPU.
