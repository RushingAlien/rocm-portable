# Portable ROCm bundle
This is a contained/standalone ROCm bundle in a dwarfs archive that can be mounted and LD_PRELOADED. Main purpose is to provide ROCm to Flatpak, as the Freedesktop Platform is still missing ROCm runtimes.

It is actually just a repackaging of Arch's ROCm packages. Why Arch? Arch's ROCm runtime is self-contained as it is built that way.


# Usage
## package.sh 
This is not to be used, this is just for transparency on how the bundle is made. And will be used in the future for CI/CD pipelines, as of now, packaging is done manually.

## install.sh
This will check for for availability of dwarfs in the system, if doesn't exist, it will download the universal binary and install it to ~/.local/bin. And then will download the portable ROCm bundle and mount it to `$HOME/.local/rocm` and set up auto mounting on login.

## integrate.sh
This will set up ROCm environment variables to a Flatpak app. Adding global env override may break things, so integrate.sh operates on a per-app basis.

