FROM ubuntu:24.04

WORKDIR /root/openwrt
ENV FORCE_UNSAFE_CONFIGURE=1

RUN set -eux \
  ; apt-get update -yqq \
  ; DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends \
    bison \
    build-essential \
    clang \
    ccache \
    ecj \
    fastjar \
    file \
    flex \
    g++ \
    gawk \
    gettext \
    git \
    java-propose-classpath \
    libelf-dev \
    libncurses5-dev \
    libpam-dev \
    libsnmp-dev \
    libssl-dev \
    make \
    python3 \
    python3-dev \
    python3-setuptools \
    rsync \
    subversion \
    swig \
    time \
    unzip \
    wget \
    xsltproc \
    zlib1g-dev \
  ; find /var/cache/ldconfig /var/cache/apt /var/lib/apt/lists /var/log -type f -delete

ADD docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
