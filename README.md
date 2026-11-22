# Kimi Desktop for Linux

Unofficial Linux port of Kimi Desktop, repackaged from the official macOS `kimi_3.2.28.dmg`.

## Quick install

Download `kimi_3.2.28_amd64.deb` from the [Releases](../../releases) page (a copy is also stored in this repo via Git LFS):

```bash
sudo dpkg -i kimi_3.2.28_amd64.deb
# If dependencies are missing:
sudo apt-get install -f
```

Then launch **Kimi** from your application menu, or run `kimi` from the terminal.

The package installs to `/usr/lib/kimi` and replaces older `kimi` packages (e.g. 3.0.0).

## Mainland China / +86 login

The macOS build defaults to the overseas site (`www.kimi.ai`), whose phone-login list does not
include `+86`. On first launch the launcher seeds the mainland region:

```
~/.config/kimi-desktop/bridge-store/region.json
{"manual":"china","lastEffective":"china"}
```

so the app starts on `www.kimi.com` and the login dialog offers `+86` plus QR login.
An existing `region.json` is never overwritten; use the dialog's “Switch to International login”
link to go back.

## Build the .deb yourself

First assemble the `kimi-linux/` directory (Electron linux-x64 runtime + a `resources/`
tree from the DMG), then run:

```bash
./build-deb.sh
```

The script produces `kimi_3.2.28_amd64.deb` in the current directory. It expects:

- `kimi-linux/` — Electron runtime with the `electron` binary and `resources/`
- `dmg/Kimi Installer 3.2.28-arm64/.../Kimi.app/Contents` — extracted macOS app (source of `app.asar`)
- `icons/kimi-{32,64,128,256,512,1024}.png`

## What's in this repo

- `README.md`
- `build-deb.sh` — Debian packaging script
- `kimi_3.2.28_amd64.deb` — prebuilt package (Git LFS)

## Technical notes

- **Source package:** `kimi_3.2.28.dmg` (macOS arm64)
- **Electron version:** v43.7.7 (linux-x64)
- **App payload:** upstream `app.asar` used unmodified
- **Linux daimon runtime** — the macOS build only ships Mach-O helpers, which made
  “initializing the workspace” fail on Linux. Replaced with:
  - Node v24.15.0 (linux-x64) at `resources/runtime/tool-node/bin/node`
  - `resources/runtime/node` — Linux wrapper around that Node
  - uv 0.13.9 (`daimon-bundle/runtime/uv/uv`)
  - CPython 3.12.16 (`daimon-bundle/runtime/python/cpython-3.12`)
  - `@node-rs/jieba-linux-x64-gnu` 2.0.4 in daimon's `node_modules`
  - `daimon-bundle/bundle.json` platform set to `linux-x64`
- Verified with the packaged build: daimon reaches `runtime_ready`, all modules
  (`automation`, `chat`, `dream`, `memory`, `search`, `share`) report success and the
  16 built-in plugins install.
- **Custom presentation skills** — the daimon built-in skills are replaced with the
  author's own versions, sharing one Linux `kimi_pptd` engine:
  - `kimi-slides` and `kimi-design` (updated SKILL/reference/scripts)
  - `pptx-ultimate` — PPT generation/editing skill, ships `scripts/runtime-fixed.tar.gz`
    containing the Nuitka-built Linux x86-64 `kimi_pptd` engine
  The engine is extracted on first use to `~/.cache/kimi-pptd-engine/` and works offline.

### Known limitations

- `kimi-slides` and the bundled `kimi-webbridge` binary are still macOS builds; slides
  conversion is skipped. WebBridge prefers `~/.kimi-webbridge/bin/kimi-webbridge` when present.
- Some app-tools that assume macOS system integrations may be unavailable.

## Disclaimer

This is an unofficial redistribution for Linux users. All trademarks and copyrights belong to Moonshot AI.
