#/usr/bin/env bash

set -e

DWARFS_VER=0.10.2
DWARFS_BIN=dwarfs-universal-$DWARFS_VER-Linux-x86_64-clang
DWARFS_URI=https://github.com/mhx/dwarfs/releases/download/v$DWARFS_VER/$DWARFS_BIN

VER=0.1.1
ROCM_VER=6.3.3
ROCM_BUNDLE=rocm-portable-$VER-$ROCM_VER.dwarfs
URI=https://share.rushingalien.my.id/rocm-portable/$ROCM_BUNDLE
ROCM_INSTALL_PATH=$HOME/.local/rocm
CHECKSUM_URI=https://share.rushingalien.my.id/rocm-portable/$ROCM_BUNDLE.checksum
ROCM_CHECKSUM=rocm-portable.checksum
SYSTEMD_MOUNT_NAME="$(systemd-escape -p $HOME/.local/rocm).mount"
TEMPLATE_FILE=rocm-portable.mount.ini
BIN_PATH=$HOME/.local/bin

# Set fallback XDG dirs
[[ ! -v XDG_CONFIG_HOME ]] && XDG_CONFIG_HOME=$HOME/.config


mkdir -p $BIN_PATH
mkdir -p $HOME/.local/rocm 
mkdir -p $XDG_CONFIG_HOME/systemd/user
mkdir -p $XDG_CONFIG_HOME/environment.d

# Check if $HOME/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "$BIN_PATH is not in PATH. Adding it to PATH..."

    # Add $HOME/.local/bin to PATH in .bash_profile
    echo 'PATH="$BIN_PATH:$PATH"' >> $XDG_CONFIG_HOME/environment.d/xdg.conf
    PATH="$BIN_PATH:$PATH"
    echo "Added $BIN_PATH to PATH via $XDG_CONFIG_HOME/environment.d/xdg.conf"
else
    echo "$BIN_PATH is already in PATH. Skipping PATH modification."
fi

# Check if dwarfs is already installed
if ! which dwarfs mount.dwarfs > /dev/null 2>&1; then
  echo "dwarfs not found in PATH. Installing dwarfs..."
  # install dwarfs
  curl -L $DWARFS_URI -o $BIN_PATH/$DWARFS_BIN &&
  chmod +x $BIN_PATH/$DWARFS_BIN
  for binary in dwarfs mkdwarfs dwarfsck dwarfsextract; do
    ln -s "$DWARFS_BIN" "$BIN_PATH/$binary"
  done
  echo '#/bin/sh' > $BIN_PATH/mount.dwarfs
  echo 'exec dwarfs "$@"' >> $BIN_PATH/mount.dwarfs
  chmod +x $BIN_PATH/mount.dwarfs
fi

download_checksum() {
    echo "Downloading checksum file..."
    curl -s $CHECKSUM_URI -o $XDG_RUNTIME_DIR/$ROCM_CHECKSUM
}

# Function to verify the checksum
verify_checksum() {
  local local_checksum=$(sha256sum $1 | awk '{print $1}')
  local remote_checksum=$(cat $2 | awk '{print $1}')

  if [[ "$local_checksum" == "$remote_checksum" ]]; then
    echo "Checksum verified successfully."
    return 0
  else
    echo "Checksum verification failed. Local: $local_checksum, Remote: $remote_checksum"
    return 1
  fi
}

# Check if the local rocm-portable.dwarfs file exists
download_and_compare_checksum() {
  if [[ ! -f $HOME/.local/rocm-portable.dwarfs ]]; then
    echo "Downloading rocm-portable.dwarfs..."
    curl $URI -o $HOME/.local/rocm-portable.dwarfs
    download_and_compare_checksum
  fi
  if ! verify_checksum $HOME/.local/rocm-portable.dwarfs $XDG_RUNTIME_DIR/$ROCM_CHECKSUM ; then
    echo "Downloading rocm-portable.dwarfs..."
    curl $URI -o $HOME/.local/rocm-portable.dwarfs
    download_and_compare_checksum
  fi
  echo "Local rocm-portable.dwarfs is up to date."
  rm $XDG_RUNTIME_DIR/$ROCM_CHECKSUM
  return 0
}

download_checksum &&
download_and_compare_checksum

# if [[ -n $XDG_DATA_HOME ]]; then
#   ICD_INSTALL_PATH=$XDG_DATA_HOME/OpenCL/vendors
# else
  ICD_INSTALL_PATH=$HOME/.local/share/OpenCL/vendors
# fi
mkdir -p $ICD_INSTALL_PATH

# install rocm bundle
echo "libamdocl64.so" > $ICD_INSTALL_PATH/rocm-portable.icd
echo "libRusticlOpenCL.so.1" > $ICD_INSTALL_PATH/rusticl.icd
echo "libnvidia-opencl.so.1" > $ICD_INSTALL_PATH/nvidia.icd
echo "libigdrcl.so" > $ICD_INSTALL_PATH/intel.icd
echo "ICD vendors file created"

[[ $(findmnt $ROCM_INSTALL_PATH | wc -l) > 1 ]] &&
  fusermount -u $ROCM_INSTALL_PATH
dwarfs $HOME/.local/rocm-portable.dwarfs $ROCM_INSTALL_PATH
echo "rocm-portable.dwarfs mounted to $ROCM_INSTALL_PATH"

flatpak --user override --filesystem=/sys/module/amdgpu:ro --filesystem=~/.local/share/OpenCL:ro --filesystem=~/.local/rocm:ro
echo -e "Added the following flatpak overrides:  \n--filesystem=/sys/module/amdgpu:ro \n--filesystem=~/.local/share/OpenCL:ro \n--filesystem=~/.local/rocm:ro"  

if [[ ! -f $XDG_CONFIG_HOME/systemd/user/$SYSTEMD_MOUNT_NAME ]]; then
  sed \
    -e "s|@ROCM_BUNDLE@|${ROCM_BUNDLE}|g" \
    -e "s|@ROCM_INSTALL_PATH@|${ROCM_INSTALL_PATH}|g" \
    $TEMPLATE_FILE > $XDG_CONFIG_HOME/systemd/user/$SYSTEMD_MOUNT_NAME
  systemctl --user daemon-reload
  systemctl --user enable $SYSTEMD_MOUNT_NAME
fi
