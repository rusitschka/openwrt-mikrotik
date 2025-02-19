#!/bin/bash -ex

COPYFILE_DISABLE=1 tar -c \
  --numeric-owner \
  --uid=0 \
  --gid=0 \
  --strip-components 1 \
  --exclude=.DS_Store \
  -vzf ../backup.tar.gz .
