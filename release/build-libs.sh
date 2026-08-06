#!/usr/bin/env zsh
set -ex

# Build DDNet dependency libraries for all platforms using Docker
# Output is placed into a ddnet-libs compatible directory structure
#
# Usage:
#   ./build-libs.sh                    # Build all platforms
#   ./build-libs.sh linux              # Build Linux only (x86_64 + x86)
#   ./build-libs.sh windows            # Build Windows only (win64 + win32)
#   ./build-libs.sh winarm64           # Build Windows ARM64 only
#   ./build-libs.sh all                # Build all platforms
#
# The output directory can be pointed directly at a ddnet-libs checkout
#
# macOS is not covered here; it needs osxcross, see ddnet-lib-update.sh.
# The per-platform lws_config.h files placed next to the websockets libs are
# inputs for the per-platform websockets/include/<platform>/lws_config.h in
# ddnet-libs.

SCRIPT_DIR="${0:A:h}"
DOCKER_DIR="$SCRIPT_DIR/docker"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/libs-output}"

TARGETS=${1:-all}

mkdir -p "$OUTPUT_DIR"

build_image() {
  docker build --platform linux/amd64 -f "$DOCKER_DIR/Dockerfile.libs-$1" -t "ddnet-libs-$1" "$DOCKER_DIR"
}

# --network host so downloads can use IPv6; the default bridge network is
# IPv4-only and not every source is reachable over IPv4 from everywhere
build_linux() {
  build_image linux
  echo "=== Building Linux x86_64 libraries ==="
  docker run --rm --platform linux/amd64 --network host \
    -v "$OUTPUT_DIR:/output" \
    -e PLATFORM=x86_64 \
    ddnet-libs-linux

  echo "=== Building Linux x86 libraries ==="
  docker run --rm --platform linux/amd64 --network host \
    -v "$OUTPUT_DIR:/output" \
    -e PLATFORM=x86 \
    ddnet-libs-linux
}

build_windows() {
  build_image windows
  echo "=== Building Windows x64 libraries ==="
  docker run --rm --platform linux/amd64 --network host \
    -v "$OUTPUT_DIR:/output" \
    -e PLATFORM=64 \
    ddnet-libs-windows

  echo "=== Building Windows x86 libraries ==="
  docker run --rm --platform linux/amd64 --network host \
    -v "$OUTPUT_DIR:/output" \
    -e PLATFORM=32 \
    ddnet-libs-windows
}

build_winarm64() {
  build_image winarm64
  echo "=== Building Windows ARM64 libraries ==="
  docker run --rm --platform linux/amd64 --network host \
    -v "$OUTPUT_DIR:/output" \
    ddnet-libs-winarm64
}

case "$TARGETS" in
  linux)
    build_linux
    ;;
  windows)
    build_windows
    ;;
  winarm64)
    build_winarm64
    ;;
  all|"")
    build_linux
    build_windows
    build_winarm64
    ;;
  *)
    echo "Unknown target: $TARGETS"
    echo "Usage: ./build-libs.sh [linux|windows|winarm64|all]"
    exit 1
    ;;
esac

# The containers write as root; hand the output to the invoking user
docker run --rm -v "$OUTPUT_DIR:/output" debian:12-slim chown -R "$(id -u):$(id -g)" /output

echo ""
echo "Library build complete. Output in: $OUTPUT_DIR"
echo "To update ddnet-libs, copy the relevant directories:"
echo "  cp -a $OUTPUT_DIR/* /path/to/ddnet-libs/"
