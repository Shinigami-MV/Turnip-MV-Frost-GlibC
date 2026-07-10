#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
PACKAGE_DIR="$ROOT_DIR/install/package"
OUTPUT_DIR="$ROOT_DIR/output"

DRIVER_NAME="${DRIVER_NAME:-Turnip MV Eclipse Base (Frost GlibC)}"
DRIVER_VERSION="${DRIVER_VERSION:-Eclipse-Base-Frost-GlibC}"
MESA_VERSION="${MESA_VERSION:-mesa-25.1.0}"

DRIVER_FILE="$PACKAGE_DIR/usr/lib/libvulkan_freedreno.so"
ICD_SOURCE="$ROOT_DIR/packaging/freedreno_icd.aarch64.json"

OUTPUT_NAME="turnip-MV-Eclipse-Base-Frost-GlibC.tzst"
OUTPUT_FILE="$OUTPUT_DIR/$OUTPUT_NAME"

echo "================================================="
echo "Packaging $DRIVER_NAME"
echo "================================================="

if [ ! -f "$DRIVER_FILE" ]; then
  echo "ERROR: driver file was not found:"
  echo "$DRIVER_FILE"
  exit 1
fi

if [ ! -f "$ICD_SOURCE" ]; then
  echo "ERROR: Vulkan ICD file was not found:"
  echo "$ICD_SOURCE"
  exit 1
fi

rm -rf "$OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$PACKAGE_DIR/usr/share/vulkan/icd.d"

cp "$ICD_SOURCE" \
  "$PACKAGE_DIR/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"

chmod 644 \
  "$PACKAGE_DIR/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"

echo "Package structure:"
find "$PACKAGE_DIR" -type f -print | sort

echo
echo "Creating TZST package..."

tar \
  --sort=name \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --mtime='UTC 2026-01-01' \
  -C "$PACKAGE_DIR" \
  -cf - . \
  | zstd -19 -T0 -o "$OUTPUT_FILE"

sha256sum "$OUTPUT_FILE" \
  > "$OUTPUT_DIR/SHA256SUMS.txt"

cat > "$OUTPUT_DIR/build-info.txt" <<EOF
Driver: $DRIVER_NAME
Version: $DRIVER_VERSION
Mesa source: $MESA_VERSION
Platform: Linux AArch64 / GlibC
Target: Winlator Frost
Vulkan driver: Turnip / Freedreno
Library: /usr/lib/libvulkan_freedreno.so
Package: $OUTPUT_NAME
EOF

echo
echo "Package successfully created:"
ls -lh "$OUTPUT_FILE"

echo
echo "SHA-256:"
cat "$OUTPUT_DIR/SHA256SUMS.txt"

echo
echo "Package contents:"
tar --use-compress-program=unzstd \
  -tf "$OUTPUT_FILE"
