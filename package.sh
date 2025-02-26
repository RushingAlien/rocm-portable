#!/usr/bin/env bash

set -e

# This script is not to be used, it is just for transparency on how the bundle is made.
# And will be used in the future for CI/CD pipelines, as of now, packaging is done manually.

# update
pacman -Syu

DWARFS_VER=0.10.2
DWARFS_BIN=dwarfs-universal-$DWARFS_VER-Linux-x86_64-clang
DWARFS_URI=https://github.com/mhx/dwarfs/releases/download/v$DWARFS_VER/$DWARFS_BIN

AMDGPU_INSTALL=
VER=0.1.1
ROCM_VER=6.3.3
ROCM_BUNDLE=rocm-portable-$VER-$ROCM_VER.dwarfs

wget https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/jammy/amdgpu-install_6.3.60303-1_all.deb
apt install ./amdgpu-install_6.3.60303-1_all.deb
# install rocm
amdgpu-install --usecase=hip,opencl --opencl=rocr --rocmrelease=$ROCM_VER
# install Dwarfs
curl $DWARFS_URI -O
chmod +x $DWARFS_BIN
ln -s $(pwd)/$DWARFS_BIN ~/.local/bin/dwarfs
ln -s $(pwd)/$DWARFS_BIN ~/.local/bin/mkdwarfs

PATH=$PATH:$HOME/.local/bin

function bundleDeps() {
  cp -a /usr/lib/libnuma.so* /opt/rocm-$ROCM_VER/lib 
}

function bundle() {
  bundleDeps
  mkdwarfs -i /opt/rocm-$ROCM_VER -o $ROCM_BUNDLE
}

bundle
sha256sum $ROCM_BUNDLE > $ROCM_BUNDLE.sha256
