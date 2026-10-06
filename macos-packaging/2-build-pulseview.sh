#!/bin/bash
# Configure and build PulseView against $WORKSPACE/prefix.
set -e
WORKSPACE="${WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
PREFIX=$WORKSPACE/prefix
export PATH="/opt/homebrew/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$(brew --prefix glibmm@2.66)/lib/pkgconfig:$(brew --prefix python@3.14)/lib/pkgconfig"
cd "$WORKSPACE/pulseview" && rm -rf build && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(brew --prefix qt)" -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j"$(sysctl -n hw.ncpu)"
echo "built: $WORKSPACE/pulseview/build/pulseview"
