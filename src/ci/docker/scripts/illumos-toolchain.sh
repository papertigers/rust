#!/bin/bash
# Copyright 2016-2017 The Rust Project Developers. See the COPYRIGHT
# file at the top-level directory of this distribution and at
# http://rust-lang.org/COPYRIGHT.
#
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.

set -eux

arch=$1
binutils_version=2.25.1
triple=$arch-sun-solaris
sysroot=/usr/local/$triple
illumos_sysroot="joyent_20170417T195210Z"

hide_output() {
  set +x
  local on_err="
echo ERROR: An error was encountered with the build.
cat /tmp/build.log
exit 1
"
  trap "$on_err" ERR
  bash -c "while true; do sleep 30; echo \$(date) - building ...; done" &
  local ping_loop_pid=$!
  #$@ &> /tmp/build.log
  $@ | tee /tmp/build.log
  trap - ERR
  kill $ping_loop_pid
  set -x
}

# First up, build binutils
mkdir binutils
cd binutils
curl https://ftp.gnu.org/gnu/binutils/binutils-${binutils_version}.tar.bz2 | tar xjf -
mkdir binutils-build
cd binutils-build
hide_output ../binutils-${binutils_version}/configure \
  --target="$triple" --with-sysroot="$sysroot"
hide_output make -j"$(getconf _NPROCESSORS_ONLN)"
hide_output make install
cd ../..
rm -rf binutils

# Next, download the illumos libraries and header files
mkdir -p "$sysroot"

URL="https://us-east.manta.joyent.com/Joyent_Dev/public/sysroot/sysroot.$illumos_sysroot.tar.gz"
curl "$URL" | tar xzf - -C "$sysroot"

# Clang can do cross-builds out of the box, if we give it the right
# flags.  (The local binutils seem to work, but they set the ELF
# header "OS/ABI" (EI_OSABI) field to SysV rather than FreeBSD, so
# there might be other problems.)
#
# The --target option is last because the cross-build of LLVM uses
# --target without an OS version ("-freebsd" vs. "-freebsd10").  This
# makes Clang default to libstdc++ (which no longer exists), and also
# controls other features, like GNU-style symbol table hashing and
# anything predicated on the version number in the __FreeBSD__
# preprocessor macro.
for tool in clang clang++; do
  tool_path=/usr/local/bin/${triple}-${tool}
  cat > "$tool_path" <<EOF
#!/bin/sh
exec $tool --sysroot=$sysroot --prefix=${sysroot}/bin "\$@" --target=$triple
EOF
  chmod +x "$tool_path"
done
