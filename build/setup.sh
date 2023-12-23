#!/bin/bash

EMSDKVER=3.1.51

# Make sure the ghostscript submodule is loaded
git submodule update --init --recursive

# Patch the ghostscript submodule
cd lib/ghostscript
git apply ../../ghostscript.patch
cd ../..

if [ -d "emsdk" ]; then
    echo "Directory emsdk exists. Skip next steps."
    # Enter that directory
    cd emsdk
else
    echo "Directory emsdk does not exist. Continue."
    # Get the emsdk repo
    git clone https://github.com/emscripten-core/emsdk.git
    # Enter that directory
    cd emsdk
    # Fetch the latest version of the emsdk (not needed the first time you clone)
    git pull
    # Checkout the correct version
    git checkout $EMSDKVER
    # Download and install the SDK tools.
    ./emsdk install $EMSDKVER
fi

# Make the SDK version active for the current user. (writes .emscripten file)
./emsdk activate $EMSDKVER

# Activate PATH and other environment variables in the current terminal
source ./emsdk_env.sh

# Build the Emscripten freetype version and copy it into ghostscript
embuilder build freetype
rm -Rf ../lib/ghostscript/freetype
mkdir ../lib/ghostscript/freetype
cp -R upstream/emscripten/cache/ports/freetype/FreeType-version_1/* ../lib/ghostscript/freetype

# Go to the emscripten directory
cd upstream/emscripten

# Remove the cache dir
rm -Rf cache

# Apply our emscripten WASI patch
patch -p1 < ../../../emscripten.patch

# Go back to the root of the build dir
cd ../../../

# Run the build script
./build.sh

# Copy the generated binaries into the wasm folder of the repository.
cp lib/ghostscript/bin/gs.wasm ../wasm
rm -Rf ../ghostscript
mv out ../ghostscript
