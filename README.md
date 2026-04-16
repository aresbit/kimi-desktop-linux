# Kimi Desktop for Linux

Unofficial Linux port of Kimi Desktop, converted from the official macOS `kimi_3.0.0.dmg`.

## Quick install

Download the pre-built `.deb` from the [Releases](../../releases) page:

```bash
sudo dpkg -i kimi_3.0.0_amd64.deb
# If dependencies are missing:
sudo apt-get install -f
```

Then launch **Kimi** from your application menu, or run `kimi` from the terminal.

## Build the .deb yourself

If you want to rebuild the package locally, first assemble the `kimi-linux/` directory
(e.g. by extracting the macOS DMG and downloading the matching Linux Electron runtime),
then run:

```bash
./build-deb.sh
```

The script will produce `kimi_3.0.0_amd64.deb` in the current directory.

## What's in this repo

- `README.md` — This file
- `build-deb.sh` — Script to build the Debian package from `kimi-linux/`

Large binaries (`kimi-linux/` runtime and `app.asar`) are **not** stored in Git; they are attached to GitHub Releases as downloadable assets.

## Technical notes

- **Source package:** `kimi_3.0.0.dmg` (macOS arm64)
- **Electron version:** v41.1.0 (linux-x64)
- **Conversion steps:**
  1. Extract DMG with `7zz`
  2. Extract `app.asar`
  3. Remove Darwin-only native modules (`fsevents`, `rollup-darwin-arm64`)
  4. Download matching Linux Electron runtime
  5. Repack `app.asar` and assemble `kimi-linux/`
  6. Build `.deb` with standard Debian packaging

## Disclaimer

This is an unofficial redistribution for Linux users. All trademarks and copyrights belong to Moonshot AI.
