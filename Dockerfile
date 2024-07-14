FROM ubuntu:22.04

WORKDIR /root/openwrt
ENV FORCE_UNSAFE_CONFIGURE=1

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
    libncurses-dev \
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
  ; find /var/cache/ldconfig /var/cache/apt /var/lib/apt/lists /var/log -type f -delete

    # bison \
    # clang \
    # flex \

ADD docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
