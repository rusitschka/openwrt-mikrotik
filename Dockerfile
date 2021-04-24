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
ADD https://github.com/openwrt/openwrt/archive/openwrt-21.02.zip /root/openwrt.zip
RUN set -eux \
  ; unzip openwrt.zip \
  ; mv openwrt-* openwrt

WORKDIR /root/openwrt
RUN set -eux \
  ; wget -q https://github.com/openwrt/openwrt/pull/3037.patch -O hap-ac2.patch \
  ; git apply hap-ac2.patch

RUN set -eux \
  ; wget -q https://github.com/openwrt/openwrt/pull/4055.patch -O cap-ac.patch \
  ; git apply cap-ac.patch

RUN set -eux \
  ; wget -q https://github.com/alaraun/openwrt/pull/1.patch -O cap-ac-patch.patch \
  ; git apply cap-ac-patch.patch

#ADD cap-ac.patch /root/openwrt/
#RUN set -eux \
#  ; git apply cap-ac.patch

# RUN set -eux \
#   ; wget -q https://github.com/openwrt/openwrt/pull/3271.patch -O optional-4k-erase.patch \
#   ; sed -e 's/^+ \t/+\t/;s/[[:space:]]*$//' -i optional-4k-erase.patch \
#   ; git apply --reject optional-4k-erase.patch

RUN set -eux \
  ; wget -q https://github.com/openwrt/openwrt/pull/3348.patch -O hap-ac-lite.patch \
  ; git apply hap-ac-lite.patch

RUN set -eux \
  ; ./scripts/feeds update -a \
  ; ./scripts/feeds install -a

ADD docker-image/build.sh /root/openwrt/
