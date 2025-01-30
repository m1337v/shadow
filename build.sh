#!/usr/bin/env bash
set -e

# Ensure script runs from the repo root
cd "$(dirname "$0")"

# Create fresh build directory
rm -rf build
mkdir -p build

# Detect available SDK version
export SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version)

# Define common build parameters
export THEOS_PACKAGE_SCHEME=rootless
export ARCHS="arm64 arm64e"
export TARGET=iphone:clang:$SDK_VERSION:14.0

# Build rootless
make clean &&
make package FINALPACKAGE=1 &&
cp -p "$(ls -dtr1 packages/*.deb | tail -1)" build/

# Build roothide
make clean &&
export THEOS_PACKAGE_SCHEME=roothide
make package FINALPACKAGE=1 &&
cp -p "$(ls -dtr1 packages/*.deb | tail -1)" build/

rm -rf $THEOS/lib/Shadow.framework

# Build rooted
make clean &&
unset THEOS_PACKAGE_SCHEME
make package FINALPACKAGE=1 &&
cp -p "$(ls -dtr1 packages/*.deb | tail -1)" build/
