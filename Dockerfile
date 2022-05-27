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
  ; fi \
  ; if [ -e mikrotik.patch ] && ! git am mikrotik.patch \
  ; then \
      git am --show-current-patch \
  ;   exit 1 \
  ; fi

RUN set -eux \
  ; ./scripts/feeds update -a \
  ; ./scripts/feeds install -a

ADD docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
