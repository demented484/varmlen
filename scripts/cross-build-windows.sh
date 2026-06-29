#!/usr/bin/env bash
# Cross-build the Windows NSIS installer ENTIRELY ON LINUX (no Windows, no CI).
# Proven on Arch. Produces:
#   src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/Varmlen_*-setup.exe
#
# One-time toolchain (Arch):
#   sudo pacman -S --needed clang nasm llvm wine        # C cross-compile + wine binfmt
#   cargo install --locked cargo-xwin                    # MSVC cross via xwin SDK
#   rustup target add x86_64-pc-windows-msvc
#   # native makensis (the bundler needs it; AUR nsis wants mingw, so build just
#   # the compiler and feed it the prebuilt stubs from the official NSIS zip):
#   #   - download nsis-3.x.zip, unzip to ~/.cache/tauri/NSIS  (Stubs/Include/Plugins)
#   #   - from the nsis source: scons SKIPSTUBS=all SKIPPLUGINS=all SKIPUTILS=all \
#   #       SKIPMISC=all SKIPDOC=all makensis
#   #   - install it as /usr/local/bin/makensis-native, then put a PATH shim
#   #     `makensis.exe` -> `NSISDIR=~/.cache/tauri/NSIS makensis-native "$@"`
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.cargo/bin:$PATH"

bash "$here/scripts/fetch-windows-bins.sh"
cd "$here"
npm install
npm run tauri build -- --runner cargo-xwin --target x86_64-pc-windows-msvc
echo "installer:"
ls -la "$here"/src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/*-setup.exe
