# openwrt-mikrotik-hap-ac2

This script supports building OpenWRT with different patches:
* Current [master branch of OpenWRT](https://github.com/openwrt/openwrt/tree/master) with
[Ipq40xx mikrotik rollup squash from john-tho](https://github.com/john-tho/openwrt/pull/2).
* 21.02.x version with [vibornoff's cAP ac patches](https://github.com/vibornoff/openwrt/tree/mikrotik-cap-ac-wip).

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

To build a tagged 21.02.x OpenWRT version which supports hAP ac2 and cAP ac use for example:
```
OPENWRT_VERSION=v21.02.1 ./build.sh
```

To build a branch, use the branch name, e.g.:
```
OPENWRT_VERSION=openwrt-21.02 ./build.sh
```

After the script finishes the resulting target builds are
copied from the Docker container to the `build` folder in the local
file system. The resulting Docker images/containers will be up to
12G each in size and can be deleted after the build finished.

The whole process takes about 45 minutes on a modern CPU.
