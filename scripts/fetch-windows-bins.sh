#!/usr/bin/env bash
# Fetch the Windows native binaries the bundle needs into src-tauri/cores/:
# xray.exe, wintun.dll (Wintun adapter driver), tun2socks.exe.
# Not committed - run before a Windows build.
set -euo pipefail
XRAY_VER="${XRAY_VER:-v25.9.11}"
T2S_VER="${T2S_VER:-v2.6.0}"
WINTUN_VER="${WINTUN_VER:-0.14.1}"

here="$(cd "$(dirname "$0")/.." && pwd)"
out="$here/src-tauri/cores"
mkdir -p "$out"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

echo "xray.exe ($XRAY_VER)"
curl -fsSL -o "$tmp/xray.zip" "https://github.com/XTLS/Xray-core/releases/download/$XRAY_VER/Xray-windows-64.zip"
python3 -c "import zipfile,sys; z=zipfile.ZipFile('$tmp/xray.zip'); open('$out/xray.exe','wb').write(z.read('xray.exe'))"

echo "wintun.dll ($WINTUN_VER)"
curl -fsSL -o "$tmp/wintun.zip" "https://www.wintun.net/builds/wintun-$WINTUN_VER.zip"
python3 -c "import zipfile; z=zipfile.ZipFile('$tmp/wintun.zip'); n=[x for x in z.namelist() if x.endswith('amd64/wintun.dll')][0]; open('$out/wintun.dll','wb').write(z.read(n))"

echo "tun2socks.exe ($T2S_VER)"
curl -fsSL -o "$tmp/t2s.zip" "https://github.com/xjasonlyu/tun2socks/releases/download/$T2S_VER/tun2socks-windows-amd64.zip"
python3 -c "import zipfile; z=zipfile.ZipFile('$tmp/t2s.zip'); n=[x for x in z.namelist() if x.lower().endswith('.exe')][0]; open('$out/tun2socks.exe','wb').write(z.read(n))"

echo "done:"; ls -la "$out"/*.exe "$out"/*.dll
