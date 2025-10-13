# Packaging Workflow (English)

[中文版本](packaging.zh.md)

## Repository Layout
- `pkgs/<pkgname>/PKGBUILD`: standard packaging script.
- `pkgs/<pkgname>/.SRCINFO`: regenerated via `makepkg --printsrcinfo`.
- `pkgs/<pkgname>/upstream.sh`: defines package update hooks for automation.
- `scripts/update-package.sh`: generic framework script that invokes package hooks.
- `.github/workflows/monitor-upstream.yml`: scheduled detection of upstream version updates.
- `.github/workflows/build-and-publish.yml`: automated building and publishing to AUR.

Patches or launcher scripts should be placed in the corresponding package directory. AppImage desktop integration (wrapper scripts, icons, `.desktop` files) should be generated in `package()` instead of committing binary assets directly.

## Auto-Update Flow
1. Execute `scripts/update-package.sh <pkgname>` to detect new upstream versions.
2. Framework calls `pkg_detect_latest()` to get the latest version number.
3. Framework calls `pkg_get_update_params(version)` to get update parameters (package downloads and calculates checksum itself).
4. Framework calls `pkg_update_files()` to update PKGBUILD (package has complete control over update logic).
5. Script outputs version change (`old -> new`). Use `--force` to force refresh when needed.

### upstream.sh Interface

The framework calls the following functions in sequence (packages must implement):

**Required Functions**:

- `pkg_detect_latest()`
  - Returns: latest version number string

- `pkg_get_update_params(version)`
  - Parameters: `version` - latest version number
  - Returns: `"<url> <filename> <pkgver> <hash_algo> <checksum>"` (space-separated)
    - `url`: download link
    - `filename`: file name
    - `pkgver`: version number in PKGBUILD (may differ from version)
    - `hash_algo`: checksum algorithm (sha256, sha512, b2, md5, etc.)
    - `checksum`: checksum value

- `pkg_update_files(url, filename, pkgver, hash_algo, checksum)`
  - Parameters: the 5 values returned from `pkg_get_update_params`
  - Function: update PKGBUILD and .SRCINFO

**Design Principles**:
- Framework only coordinates, does not control business logic
- Packages decide their own download, checksum algorithm, version format
- Unified interface format, packages are fully autonomous

## Manual Verification Checklist
- `makepkg --cleanbuild --syncdeps`
- `namcap PKGBUILD` and `namcap *.pkg.tar.zst`
- Install test: `sudo pacman -U kdenlive-appimage-pure-*.pkg.tar.zst`, verify launch and icon.
- Cleanup: `rm -rf src pkg *.pkg.tar.* *.AppImage`

## Pre-Release Checklist
- Always commit both `PKGBUILD` and `.SRCINFO`.
- PRs or CI must include build/test logs.
- If upstream directory structure changes, update `upstream.sh` parsing logic promptly and output clear error messages for quick CI troubleshooting.
