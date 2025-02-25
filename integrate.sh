#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <flatpak-app-id-1> <flatpak-app-id-2> ..."
  exit 1
fi

for app_id in "$@"; do
  echo "Processing $app_id..."

  # Get the LD_LIBRARY_PATH value from flatpak info --show-permissions
  ld_library_path=$(flatpak info --show-permissions "$app_id" | grep -oP 'LD_LIBRARY_PATH=\K[^ ]+')

  if [ -n "$ld_library_path" ]; then
    temp_var="$ld_library_path:$HOME/.local/rocm/lib"
  else
    temp_var="/app/lib:/usr/lib:$HOME/.local/rocm/lib"
  fi

  echo "Setting LD_LIBRARY_PATH for $app_id to: $temp_var"

  # Apply the override
  flatpak --user override --env=LD_LIBRARY_PATH="$temp_var" --env=OCL_ICD_VENDORS="$HOME/.local/share/OpenCL/vendors/rocm-portable.icd" "$app_id"

  echo "Override applied for $app_id."
done

echo "All done!"