FROM ubuntu

RUN set -eux \
  ; apt-get update -yqq \
  ; DEBIAN_FRONTEND=noninteractive apt-get install -yqq \
    build-essential \
    ccache \
    ecj \
    fastjar \
    file \
    g++ \
    gawk \
    gettext \
    git \
    java-propose-classpath \
    libelf-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libssl-dev \
    python \
    python2.7-dev \
    python3 \
    unzip \
    wget \
    python3-distutils \
    python3-setuptools \
    rsync \
    subversion \
    swig \
    time \
    xsltproc \
    zlib1g-dev

WORKDIR /root
RUN set -eux \
#  ; wget -q https://github.com/openwrt/openwrt/archive/master.zip -O openwrt.zip \
  ; wget -q https://github.com/openwrt/openwrt/archive/openwrt-21.02.zip -O openwrt.zip \
  ; unzip openwrt.zip \
  ; mv openwrt-* openwrt

WORKDIR /root/openwrt
RUN set -eux \
  ; cd /root/openwrt \
  ; wget -q https://github.com/openwrt/openwrt/pull/3037.patch -O hap-ac.patch \
  ; git apply hap-ac.patch

RUN set -eux \
  ; ./scripts/feeds update -a \
  ; ./scripts/feeds install -a

ENV FORCE_UNSAFE_CONFIGURE=1
ADD config.txt /root/openwrt/.config
RUN set -eux \
  ; make defconfig \
  ; if make V=s; then echo success; else make V=sc || true; echo FAILED; fi
