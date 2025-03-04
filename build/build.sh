#!/bin/bash
set -euo pipefail

OUT_DIR="$PWD/out"
ROOT="$PWD"
EMCC_FLAGS_DEBUG="-g"
EMCC_FLAGS_RELEASE="-O2"

export CPPFLAGS="-I$OUT_DIR/include"
export LDFLAGS="-L$OUT_DIR/lib"
export PKG_CONFIG_PATH="$OUT_DIR/lib/pkgconfig"
export EM_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
export CFLAGS="$EMCC_FLAGS_DEBUG"
export CXXFLAGS="$CFLAGS"
export TARGET_ARCH_FILE="$ROOT/arch_wasm.h"
#export EMCC_DEBUG=1

mkdir -p "$OUT_DIR"

cd "$ROOT/lib/ghostscript"

# There is a bug in this version of Ghostscript that prevents passing in gcc to compile the build tools, replace the var manually.
sed -i "s/CCAUX=@CC@/CCAUX=gcc/g" base/Makefile.in

# Run the following to avoid "cannot find required auxiliary files: config.guess config.sub"
autoreconf --install

emconfigure ./autogen.sh \
  CFLAGSAUX= CPPFLAGSAUX= \
  --host="wasm32-unknown-linux" \
  --prefix="$OUT_DIR" \
  --disable-cups \
  --disable-dbus \
  --disable-gtk \
  --with-system-libtiff

export GS_LDFLAGS="\
-s ALLOW_MEMORY_GROWTH=1 \
-s WASM=1 \
-s ALLOW_MEMORY_GROWTH=1 \
-s STANDALONE_WASM=1 \
-sERROR_ON_UNDEFINED_SYMBOLS=0 \
-s USE_ZLIB=1 \
-s WASM_BIGINT=1 \
-g \
--profile"

emmake make \
  LDFLAGS="$LDFLAGS $GS_LDFLAGS" \
  prefix="$OUT_DIR" \
  -j install

exit 1
