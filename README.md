# Portable ROCm bundle
This is a contained/standalone ROCm bundle in a dwarfs archive that can be mounted and LD_PRELOADED. Main purpose is to provide ROCm to Flatpak, as the Freedesktop Platform is still missing ROCm runtimes.

It is actually just a repackaging of Arch's ROCm packages. Why Arch? Arch's ROCm runtime is self-contained as it is built that way.

# Usage
There are three scripts, concerning installing, you only need two: `install.sh` and `integrate.sh`. 
## package.sh 
This is not to be used, this is just for transparency on how the bundle is made. And will be used in the future for CI/CD pipelines, as of now, packaging is done manually.

## install.sh
This will check for for availability of dwarfs in the system, if doesn't exist, it will download the universal binary and install it to ~/.local/bin. And then will download the portable ROCm bundle and mount it to `$HOME/.local/rocm` and set up auto mounting on login.

## integrate.sh
This will set up ROCm environment variables to a Flatpak app. Adding global env override may break things, so integrate.sh operates on a per-app basis.
```
./integrate.sh <flatpak-app-id-1> <flatpak-app-id-2> ...
```

# Manual setup
1. Install dwarfs with method of your choosing (tarball, AUR, universal binary, COPR, PPA, etc)
2. Download one of the portable ROCm bundles below
3. Use dwarfs to mount the bundle to `$HOME/.local/rocm`
4. Create icd file `$HOME/.local/rocm/etc/OpenCL/vendors/rocm-portable.icd` with content:
```
libamdocl64.so
```
or
```
$HOME/.local/rocm/lib/libamdocl64.so
```
Note $HOME should be expanded to your home directory, as in you write the absolute path to the file.
5. Add these global flatpak overrides 
  - `--filesystem=~/.local/share/OpenCL:ro`
  - `--filesystem=~/.local/rocm:ro`
  - `--filesystem=/sys/module/amdgpu:ro`
6. Run `integrate.sh` to set up ROCm environment variables for your app of choice (or add overrides yourself)

# Releases
- https://share.rushingalien.my.id/rocm-portable/rocm-portable-0.1.0-6.2.4.dwarfs