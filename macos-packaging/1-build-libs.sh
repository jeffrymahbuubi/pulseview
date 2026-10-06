#!/bin/bash
# Build libsigrokdecode + libsigrok (with C++ bindings) into $WORKSPACE/prefix.
# Expects $WORKSPACE to contain checkouts of pulseview, libsigrok, libsigrokdecode (see README.md).
set -e
WORKSPACE="${WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
PREFIX=$WORKSPACE/prefix
export PATH="/opt/homebrew/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$(brew --prefix glibmm@2.66)/lib/pkgconfig:$(brew --prefix python@3.14)/lib/pkgconfig"
export LIBTOOLIZE=glibtoolize
JOBS=$(sysctl -n hw.ncpu)
cd "$WORKSPACE/libsigrokdecode" && ./autogen.sh && ./configure --prefix="$PREFIX" && make -j"$JOBS" && make install
cd "$WORKSPACE/libsigrok" && ./autogen.sh && ./configure --prefix="$PREFIX" --enable-cxx --disable-python --disable-java --disable-ruby && make -j"$JOBS" && make install
echo "libs done: $PREFIX"
