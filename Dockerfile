# -*- mode: Fundamental; indent-tabs-mode: nil -*-

FROM debian:12.10
LABEL maintainer=fozztexx@fozztexx.com

ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOF
  set -e
  apt-get update
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    flex \
    git \
    less \
    sudo \
    unzip \
    wget \
    yacc \
    ;
  rm -rf /var/lib/apt/lists/*
EOF

# Install cc65
RUN <<EOF
  set -e
  cd /tmp
  git clone https://github.com/cc65/cc65.git
  cd cc65
  export PREFIX=/usr/local
  make
  make install
  cd /tmp
  rm -rf cc65*
EOF

# Install LWTOOLS for CMOC
ARG LWTOOLS_VERSION
RUN <<EOF
  set -e
  cd /tmp
  wget http://www.lwtools.ca/releases/lwtools/lwtools-${LWTOOLS_VERSION}.tar.gz
  tar -xf lwtools-${LWTOOLS_VERSION}.tar.gz
  cd lwtools-${LWTOOLS_VERSION}
  make
  make install
  cd /tmp
  rm -rf lwtools*
EOF

# Install CMOC
ARG CMOC_VERSION
RUN <<EOF
  set -e
  cd /tmp
  wget http://gvlsywt.cluster051.hosting.ovh.net/dev/cmoc-${CMOC_VERSION}.tar.gz
  tar -xf cmoc-${CMOC_VERSION}.tar.gz
  cd cmoc-${CMOC_VERSION}
  ./configure
  make
  make install
  cd /tmp
  rm -rf cmoc*
EOF

# Install decb
RUN <<EOF
  set -e
  cd /tmp
  git clone https://github.com/n6il/toolshed.git
  cd toolshed
  make -C build/unix APPS=decb install
  cd /tmp
  rm -rf toolshed
EOF

# Install OpenWatcom
ARG OW2_VERSION
ENV WATCOM=/opt/watcom
ENV INCLUDE=${WATCOM}/h
ENV PATH=${PATH}:${WATCOM}/binl

# ARG OW2_RELEASE_VERSION=2025-03-01-Build
# ARG OW2_INSTALLER=open-watcom-2_0-c-linux-x64
# ADD https://github.com/open-watcom/open-watcom-v2/releases/download/${OW2_RELEASE_VERSION}/${OW2_INSTALLER} /tmp

RUN <<EOF
  set -e
  cd /tmp
  REPO=open-watcom-v2
  git clone -b ${OW2_VERSION} https://github.com/open-watcom/${REPO}.git
  cd ${REPO}
  . ./setvars.sh
  export OWDOCBUILD=0 OWNOWGML=1
  ./build.sh
  cd bld
  builder rel
  cd ..
  mkdir -p ${WATCOM}
  cp -R rel/* ${WATCOM}/.

  printf "#include <stdio.h>\nvoid main() { printf(\"Hello Watcom!\\\n\"); }\n" > hello.c
  wcc -0 hello.c
  wlink system dos name hello.exe file hello.o
  rm -f hello.o hello.c hello.exe

  cd /tmp
  rm -rf ${REPO}
EOF

# Install PlatformIO
RUN <<EOF
  set -e
  apt-get update
  apt-get install -y --no-install-recommends \
    pipx \
    ;
  rm -rf /var/lib/apt/lists/*
  PIPX_HOME=/usr/local/pipx PIPX_BIN_DIR=/usr/local/bin pipx install platformio
EOF
ENV PLATFORMIO_CORE_DIR=/workspace/.platformio

# Requirements for building FujiNet LWM
RUN <<EOF
  set -e
  apt-get update
  apt-get install -y --no-install-recommends \
    cmake \
    libexpat-dev \
    libmbedtls-dev \
    ;
  rm -rf /var/lib/apt/lists/*
  PIPX_HOME=/usr/local/pipx PIPX_BIN_DIR=/usr/local/bin pipx install abimap
EOF

# Install Mad-Assembler "mads"
RUN <<EOF
  set -e
  cd /tmp
  git clone https://github.com/tebe6502/Mad-Assembler.git
  cp Mad-Assembler/bin/linux_x86_64/mads /usr/local/bin
  rm -rf Mad-Assembler
EOF

# Install atasm to build dir2atr
RUN <<EOF
  set -e

  apt-get update
  apt-get install -y --no-install-recommends \
    libz-dev \
    ;
  rm -rf /var/lib/apt/lists/*

  cd /tmp
  git clone https://github.com/CycoPH/atasm.git
  cd atasm/src
  make
  mkdir -p /usr/local/doc/atasm
  make install
  cd /tmp
  rm -rf atasm
EOF

# Install dir2atr
RUN <<EOF
  set -e

  apt-get update
  apt-get install -y --no-install-recommends \
    libncurses5-dev \
    ;
  rm -rf /var/lib/apt/lists/*

  cd /tmp
  git clone https://github.com/HiassofT/AtariSIO.git
  cd AtariSIO
  make tools
  make tools-install
  cd /tmp
  rm -rf AtariSIO
EOF

# Install AppleCommander
ARG AC_VER=1.10.1
RUN <<EOF
  set -e

  apt-get update
  apt-get install -y --no-install-recommends \
    default-jdk \
    ;
  rm -rf /var/lib/apt/lists/*

  cd /usr/local/bin
  AC_URL=https://github.com/AppleCommander/AppleCommander/releases/download/${AC_VER}
  AC_JAR=AppleCommander-ac-${AC_VER}.jar
  wget ${AC_URL}/${AC_JAR}
  cat >ac <<ACEOF
#!/bin/sh
exec java -jar "\$(dirname \$0)"/--ACJAR-- \$@
ACEOF
  sed -i -e "s/--ACJAR--/${AC_JAR}/" ac
  chmod +x ac
EOF

# Install 1541 tools
RUN <<EOF
  set -e
  cd /tmp
  git clone https://bitbucket.org/ptv_claus/cc1541.git
  cd cc1541
  make
  make install
  cd /tmp
  rm -rf cc1541
EOF

ARG WSUSER=wario
RUN set -e \
    ; useradd -s /bin/bash -m ${WSUSER} \
    ; echo "${WSUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    ;

COPY cntnr-init /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/cntnr-init"]
