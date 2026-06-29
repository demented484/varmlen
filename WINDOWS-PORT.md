# Windows port (work in progress - branch `windows-port`)

Brings the Varmlen xray VPN client to Windows. Status: **M1 code-complete and the
Windows NSIS installer cross-builds entirely on Linux** (the MSVC target compiles
+ links and `Varmlen_0.1.1_x64-setup.exe` is produced). The Linux build still
compiles clean too. Only the runtime data-plane behaviour is unverified (needs a
real Windows VM + a live server).

## Architecture

Mirrors the Android data plane (not the Linux native-tun one), because xray's
native Windows tun is experimental and the Linux path depends on Linux-only
machinery (fwmark, `/proc` process routing, nft):

```
system apps -> Wintun adapter (10.7.0.1/24, default route) -> tun2socks.exe
            -> SOCKS5 127.0.0.1:2081 -> xray.exe (vless/reality) -> server
```

- `xray.exe` runs as a local SOCKS proxy (the existing `TunMode::Tun2socks`
  config path already emits exactly this and drops per-app routing).
- `tun2socks.exe` owns the Wintun adapter and bridges it to the SOCKS proxy.
- Routing, DNS and a kill switch are applied from the (admin-elevated) app with
  `netsh` / `route` - there is no separate helper. The app requests
  `requireAdministrator` via an embedded manifest (UAC prompt at launch).
- Anti-loop: a host route for each server IP via the physical gateway keeps
  xray's own dial to the server off the tun.

Code: `src-tauri/src/win_vpn.rs` (the whole data plane), `#[cfg(windows)]` arms in
`src-tauri/src/vpn.rs`, `build.rs` (manifest), `tauri.windows.conf.json`
(bundles `xray.exe` + `wintun.dll` + `tun2socks.exe`, NSIS perMachine).

## Building

Three bundled binaries are NOT in git - they are fetched at build time:
`xray.exe` + `wintun.dll` (from XTLS/Xray-core `Xray-windows-64.zip`) and
`tun2socks.exe` (from xjasonlyu/tun2socks). They go in `src-tauri/cores/`.

**Option A - cross-build on Linux (what we use).** `scripts/cross-build-windows.sh`
produces the NSIS installer with no Windows machine and no CI. One-time toolchain
setup is documented at the top of that script (cargo-xwin + clang/nasm/llvm +
wine + a native `makensis` fed the prebuilt NSIS stubs). Output:
`src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/Varmlen_*-setup.exe`.

**Option B - GitHub Actions.** `.github/workflows/windows.yml` builds on a
`windows-latest` runner (native MSVC, no cross-compile hacks). Disabled while the
account's Actions are billing-locked; re-enable by fixing GitHub billing.

**Option C - build inside the Windows VM** (`~/win-vm`, see its README):
1. Install Rust (rustup), Node 20, and the MSVC C++ build tools (Visual Studio
   Build Tools, "Desktop development with C++"). WebView2 ships with Windows 11.
2. Clone this repo, `git checkout windows-port`.
3. Fetch the three binaries into `src-tauri/cores/` (same URLs as the CI step).
4. `npm install && npm run tauri build`. Installer lands in
   `src-tauri/target/release/bundle/nsis/`.

## Verified vs not

- Verified: the Linux build compiles after the cfg split; the **Windows MSVC
  target compiles + links** (`win_vpn.rs` + all arms) via cargo-xwin; the **NSIS
  installer bundles** (cross-built on Linux).
- NOT verified (needs a real Windows VM + a live vless/reality server): all
  runtime behaviour - adapter creation, routing, anti-loop, DNS, kill switch.

## VM-validate / v0.2 TODO (cannot be done without a real Windows + a live server)

- Per-site DIRECT exclusions loop on Windows for now (their dials default into
  the tun). v0.1 is effectively full-tunnel until `sockopt.interface` (bind
  xray's outbound to the physical adapter) is wired and validated. Until then,
  prefer general/full-tunnel use.
- Confirm `route print -4` gateway parsing, the `wintun` adapter name, DNS
  hijack, and the `netsh advfirewall` kill switch on a real adapter.
- Harden: swap `netsh` kill switch -> WFP, `route`/`netsh` -> IP Helper, and add
  Windows-Firewall per-process split for true per-app.
