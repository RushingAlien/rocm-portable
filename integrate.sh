#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <flatpak-app-id-1> <flatpak-app-id-2> ..."
  exit 1
fi

CMD=(--device=all)

for app_id in "$@"; do
  echo "Processing $app_id..."

  # Get the LD_LIBRARY_PATH value from flatpak info --show-permissions
  ld_library_path=$(flatpak info --show-permissions "$app_id" | grep -oP 'LD_LIBRARY_PATH=\K[^ ]+')

  # Get the OCL_ICD_VENDORS value from flatpak info --show-permissions
  ocl_icd_vendors=$(flatpak info --show-permissions "$app_id" | grep -oP 'OCL_ICD_VENDORS=\K[^ ]+')
  
  [[ -n $ld_library_path ]] && ld_library_path="$ld_library_path:"
  [[ -n $ocl_icd_vendors ]] && ocl_icd_vendors="$ocl_icd_vendors:"

  [[ $(echo "$ld_library_path" | grep -c "$HOME/.local/rocm/lib") == 0 ]] &&
    CMD+=(--env=LD_LIBRARY_PATH="$ld_library_path$HOME/.local/rocm/lib")

  [[ $(echo "$ocl_icd_vendors" | grep -c "$HOME/.local/share/OpenCL/vendors") == 0 ]] &&
    CMD+=(--env=OCL_ICD_VENDORS="$ocl_icd_vendors$HOME/.local/share/OpenCL/vendors")

  echo "Applying overrides"

  # Apply the override
  flatpak --user override "${CMD[@]}" "$app_id"

  echo "Override applied for $app_id."
done

echo "All done!"