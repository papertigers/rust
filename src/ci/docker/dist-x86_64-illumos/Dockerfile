FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
  clang \
  make \
  file \
  curl \
  ca-certificates \
  python2.7 \
  git \
  cmake \
  sudo \
  bzip2 \
  xz-utils \
  wget \
  libssl-dev \
  pkg-config

COPY scripts/illumos-toolchain.sh /tmp/
RUN /tmp/illumos-toolchain.sh x86_64

COPY scripts/sccache.sh /scripts/
RUN sh /scripts/sccache.sh

ENV \
    AR_x86_64_sun_solaris=x86_64-sun-solaris-ar \
    CC_x86_64_sun_solaris=x86_64-sun-solaris-clang \
    CXX_x86_64_sun_solaris=x86_64-sun-solaris-clang++

ENV HOSTS=x86_64-sun-solaris

ENV RUST_CONFIGURE_ARGS --enable-extended --disable-docs
ENV SCRIPT python2.7 ../x.py dist --host $HOSTS --target $HOSTS
