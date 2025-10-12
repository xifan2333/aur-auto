# Packaging Workflow (English)

[中文版本](packaging.zh.md)

## Repository Layout
- `pkgs/<pkgname>/PKGBUILD`: canonical package recipe.
- `pkgs/<pkgname>/.SRCINFO`: regenerated via `makepkg --printsrcinfo`.
- `pkgs/<pkgname>/upstream.sh`: package-specific hooks for update automation.
- `scripts/update-package.sh`: framework script invoking per-package hooks.

Auxiliary patches or launchers should live alongside the PKGBUILD. AppImage desktop integration (wrappers, icons, `.desktop` entries) is generated inside `package()` instead of being committed as static files.

## Auto-Update Flow
1. Run `scripts/update-package.sh <pkgname>` to detect upstream releases.
2. The package hook reports the download URL; the framework fetches the artifact and calculates the new SHA256.
3. `pkg_update_files` writes `pkgver`, resets `pkgrel`, updates `source_x86_64`/`sha256sums_x86_64`, and calls `makepkg --printsrcinfo > .SRCINFO`.
4. The script prints the version transition (`old -> new`). Use `--force` to refresh metadata even when versions match.

Current example:
- `kdenlive-appimage-pure`: AppImage build sourced from KDE downloads with automatic version discovery.

## Manual Verification Checklist
- `makepkg --cleanbuild --syncdeps`
- `namcap PKGBUILD` and `namcap *.pkg.tar.zst`
- Install test: `sudo pacman -U kdenlive-appimage-pure-*.pkg.tar.zst`, verify launch and icon.
- Cleanup: `rm -rf src pkg *.pkg.tar.* *.AppImage`

## Release Gates
- Commit both `PKGBUILD` and `.SRCINFO`.
- Attach build/test logs in PRs or CI artifacts.
- If upstream structure changes, update `upstream.sh` promptly and emit clear error messages so CI fails fast.
