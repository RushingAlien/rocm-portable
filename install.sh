#/usr/bin/env bash

set -e

DWARFS_VER=0.10.2
DWARFS_BIN=dwarfs-universal-$DWARFS_VER-Linux-x86_64-clang
DWARFS_URI=https://github.com/mhx/dwarfs/releases/download/v$DWARFS_VER/$DWARFS_BIN

VER=0.1.0
ROCM_VER=6.2.4
ROCM_BUNDLE=rocm-portable-$VER-$ROCM_VER.dwarfs
URI=https://share.rushingalien.my.id/rocm-portable/$ROCM_BUNDLE
ROCM_INSTALL_PATH=$HOME/.local/rocm

mkdir -p $HOME/.local/bin
mkdir -p $HOME/.local/rocm 
# install dwarfs
curl $DWARFS_URI -o $HOME/.local/bin/$DWARFS_BIN &&

ln -s $DWARFS_BIN $HOME/.local/bin/dwarfs
ln -s $DWARFS_BIN $HOME/.local/bin/mkdwarfs
ln -s $DWARFS_BIN $HOME/.local/bin/dwarfsck

# download rocm bundle
curl $URI -o $XDG_DATA_HOME/.local/rocm-portable.dwarfs &&

# if [[ -n $XDG_DATA_HOME ]]; then
#   ICD_INSTALL_PATH=$XDG_DATA_HOME/OpenCL/vendors
# else
  ICD_INSTALL_PATH=$HOME/.local/share/OpenCL/vendors
# fi
mkdir -p $ICD_INSTALL_PATH

# install rocm bundle

echo "$ROCM_INSTALL_PATH/lib/libamdocl64.so" > $ICD_INSTALL_PATH/rocm-portable.icd
$HOME/.local/bin/dwarfs $HOME/.local/rocm-portable.dwarfs $ROCM_INSTALL_PATH
echo "$HOME/.local/bin/dwarfs $HOME/.local/rocm-portable.dwarfs $ROCM_INSTALL_PATH" >> $HOME/.bash_profile

flatpak --user override --filesystem=/sys/module/amdgpu:ro --filesystem=~/.local/share/OpenCL:ro --filesystem=~/.local/rocm:ro