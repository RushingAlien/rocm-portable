#!/usr/bin/env bash

set -e

# This script is not to be used, it is just for transparency on how the bundle is made.
# And will be used in the future for CI/CD pipelines, as of now, packaging is done manually.

# update
pacman -Syu

ROCM_PKGS=(rocm-opencl-runtime hip-runtime-amd comgr rocm-hip-runtime hiprt numactl google-glog flags ncurses)
DWARFS_VER=0.10.2
DWARFS_BIN=dwarfs-universal-$DWARFS_VER-Linux-x86_64-clang
DWARFS_URI=https://github.com/mhx/dwarfs/releases/download/v$DWARFS_VER/$DWARFS_BIN

# install rocm
pacman -S ${ROCM_PKGS[@]}
# install Dwarfs
curl $DWARFS_URI -O
chmod +x $DWARFS_BIN
ln -s $(pwd)/$DWARFS_BIN ~/.local/bin/dwarfs
ln -s $(pwd)/$DWARFS_BIN ~/.local/bin/mkdwarfs

PATH=$PATH:$HOME/.local/bin

function bundleDeps() {
  # copy dependencies
  cp -a /usr/lib/{libnuma.so*,libglog.so*,libgflags.so*,libncursesw.so*} /opt/rocm/lib
  
  # turn absoulte symlinks into relative symlinks
  ln -sf ../LLVMgold.so /opt/rocm/lib/llvm/lib/bfd-plugins/LLVMgold.so
  ln -sf lib/llvm /opt/rocm/llvm
}

function bundle() {
  bundleDeps
  mkdwarfs -i /opt/rocm -o rocm.dwarfs
}

bundle
