#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
MESA_DIR="$ROOT_DIR/mesa"
BUILD_DIR="$ROOT_DIR/build"
INSTALL_DIR="$ROOT_DIR/install"
PACKAGE_DIR="$INSTALL_DIR/package"

DRIVER_NAME="${DRIVER_NAME:-Turnip MV Eclipse Base (Frost GlibC)}"

echo "================================================="
echo "$DRIVER_NAME"
echo "================================================="
echo "Repository: $ROOT_DIR"
echo "Mesa source: $MESA_DIR"
echo "Build directory: $BUILD_DIR"
echo "Install directory: $INSTALL_DIR"
echo

if [ ! -f "$MESA_DIR/meson.build" ]; then
  echo "ERROR: Mesa source was not found in:"
  echo "$MESA_DIR"
  exit 1
fi

rm -rf "$BUILD_DIR"
rm -rf "$INSTALL_DIR"

mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$PACKAGE_DIR/usr/lib"

echo "Configuring Mesa Turnip..."

meson setup "$BUILD_DIR" "$MESA_DIR" \
  --prefix=/usr \
  --libdir=lib \
  --buildtype=release \
  -Dplatforms=x11 \
  -Dgallium-drivers= \
  -Dvulkan-drivers=freedreno \
  -Dfreedreno-kmds=kgsl \
  -Dglx=disabled \
  -Degl=disabled \
  -Dgbm=disabled \
  -Dllvm=disabled \
  -Dshared-glapi=disabled \
  -Dbuild-tests=false \
  -Dstrip=true

echo
echo "Compiling Turnip..."

ninja -C "$BUILD_DIR"

echo
echo "Installing build files..."

DESTDIR="$INSTALL_DIR" ninja -C "$BUILD_DIR" install

echo
echo "Searching for libvulkan_freedreno.so..."

DRIVER="$(find "$INSTALL_DIR" \
  -type f \
  -name 'libvulkan_freedreno.so*' \
  | head -n 1)"

if [ -z "$DRIVER" ]; then
  echo "ERROR: libvulkan_freedreno.so was not generated."
  echo
  echo "Installed files:"
  find "$INSTALL_DIR" -maxdepth 8 -type f | sort
  exit 1
fi

cp "$DRIVER" \
  "$PACKAGE_DIR/usr/lib/libvulkan_freedreno.so"

chmod 755 \
  "$PACKAGE_DIR/usr/lib/libvulkan_freedreno.so"

echo
echo "Driver generated successfully:"
file "$PACKAGE_DIR/usr/lib/libvulkan_freedreno.so"

echo
echo "Driver size:"
ls -lh "$PACKAGE_DIR/usr/lib/libvulkan_freedreno.so"

echo
echo "Turnip MV Eclipse Base build completed."
