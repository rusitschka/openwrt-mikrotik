# openwrt-mikrotik-hap-ac2

This script will patch current
[master branch of OpenWRT](https://github.com/openwrt/openwrt/tree/master) with
[Ipq40xx mikrotik rollup squash from john-tho](https://github.com/john-tho/openwrt/pull/2).

It's all done through Docker images/containers so you need to
have Docker installed.

OpenWRT >= 21.02 already comes with hAP ac2 support built-in. The name of this project has
historic reasons. When I started this project hAP ac2 support had to patched into official
OpenWRT source. But nowadays cAP ac support (and others) is still missing from master and
still requires a patch.

To build OpenWRT for lots of Mikrotik devices execute:
```
./build.sh
```

After the script finishes the resulting target builds are
copied from the Docker container to the `build` folder in the local
file system. The resulting Docker images/containers will be up to
12G each in size and can be deleted after the build finished.

The whole process takes about 45 minutes on a modern CPU.
