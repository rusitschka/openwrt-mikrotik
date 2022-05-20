FROM ubuntu

WORKDIR /root

RUN set -eux \
  ; apt-get update -yqq \
  ; DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends \
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
    libpam-dev \
    libsnmp-dev \
    libssl-dev \
    make \
    python3 \
    python3-dev \
    python3-distutils \
    python3-setuptools \
    rsync \
    subversion \
    swig \
    time \
    unzip \
    wget \
    xsltproc \
    zlib1g-dev \
  ; git clone https://github.com/openwrt/openwrt.git \
  ; git config --global user.email "noreply@example.com" \
  ; git config --global user.name "No Name"

WORKDIR /root/openwrt

ARG OPENWRT_VERSION
ENV OPENWRT_VERSION=${OPENWRT_VERSION}

ARG OPENWRT_BUILD_DATE
ENV OPENWRT_BUILD_DATE=${OPENWRT_BUILD_DATE}

RUN set -eux \
  ; git checkout $OPENWRT_VERSION \
  ; if [ "$OPENWRT_VERSION" = "master" ] \
  ; then \
      wget -q https://github.com/john-tho/openwrt/pull/2.patch -O mikrotik.patch \
  ; else \
      wget -q https://github.com/openwrt/openwrt/compare/master...vibornoff:mikrotik-cap-ac-wip.patch -O mikrotik.patch \
  ;   sed -i 's/passtrough/passthrough/g' mikrotik.patch \
  ; fi \
  ; if ! git am mikrotik.patch \
  ; then \
      git am --show-current-patch \
  ;   exit 1 \
  ; fi

# # cAP ac
# RUN set -eux \
#   ; wget -q https://github.com/openwrt/openwrt/compare/master...vibornoff:mikrotik-cap-ac-wip.patch -O cap-ac.patch \
#   ; sed -i 's/passtrough/passthrough/g' cap-ac.patch \
#   ; git apply cap-ac.patch

# RUN set -eux \
#   ; wget -q https://github.com/openwrt/openwrt/pull/4055.patch -O cap-ac.patch \
#   ; git apply cap-ac.patch

# RUN set -eux \
#   ; wget -q https://github.com/alaraun/openwrt/pull/1.patch -O cap-ac-patch.patch \
#   ; git apply cap-ac-patch.patch

# hAP ac lite
# RUN set -eux \
#   ; wget -q https://github.com/openwrt/openwrt/pull/3271.patch -O optional-4k-erase.patch \
#   ; sed -e 's/^+ \t/+\t/;s/[[:space:]]*$//' -i optional-4k-erase.patch \
#   ; git apply --reject optional-4k-erase.patch

# RUN set -eux \
#   ; wget -q https://github.com/openwrt/openwrt/pull/3348.patch -O hap-ac-lite.patch \
#   ; git apply hap-ac-lite.patch

RUN set -eux \
  ; ./scripts/feeds update -a \
  ; ./scripts/feeds install -a

ADD docker-image/build.sh /root/openwrt/
