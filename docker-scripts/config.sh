#!/bin/bash -ex

make menuconfig
./scripts/diffconfig.sh
