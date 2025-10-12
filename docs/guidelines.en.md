# Repository Guidelines (English)

[中文版本](guidelines.zh.md)

## Project Structure & Module Organization
This repository automates Arch User Repository maintenance: it monitors upstream releases, rebuilds packages, and publishes to AUR. GitHub Actions workflows reside in `.github/workflows/`—`monitor-upstream.yml` handles scheduled detection, while `release.yml` publishes successful builds. Shared tooling lives in `scripts/`; orchestration happens in `update-package.sh`, and reusable helpers will be added under `scripts/lib/`. Each package stores its materials in `pkgs/<pkgname>/`, including `PKGBUILD`, `.SRCINFO`, and a package-specific `upstream.sh`.

## Build, Test, and Development Commands
Activate any project toolchain via `source scripts/env.sh` (when available) and run scripts with `./scripts/<name>.sh`. Typical local checks:
- `scripts/update-package.sh kdenlive-appimage-pure` – detect upstream releases, refresh PKGBUILD and `.SRCINFO`.
- `makepkg --syncdeps --cleanbuild` – reproducible local build.
- `namcap PKGBUILD` & `namcap *.pkg.tar.zst` – static quality checks.
- `extra-x86_64-build` – clean-chroot validation mirroring the AUR toolchain.

## Coding Style & Naming Conventions
Shell scripts target Bash, begin with `set -euo pipefail`, and use two-space indentation. Python helpers (when present) should follow `black` and `isort` defaults and export type hints on public functions. Name directories with lowercase-kebab style; shell files mirror that convention, while Python modules use snake_case. Reuse shared logging utilities under `scripts/lib/` to keep CI output consistent.

## Testing Guidelines
Execute `makepkg --syncdeps --cleanbuild` before publishing, and ensure `namcap` passes with no critical findings. Add regression coverage whenever you fix a bug; automation scripts should ship with minimal bats/shunit2 tests where feasible. CI jobs must build within a clean chroot, run QA, and upload artifacts plus logs for review.

## Commit & Pull Request Guidelines
Adopt Conventional Commits (`feat:`, `fix:`, `ci:`). Include upstream version bumps in commit subjects (e.g., `fix: bump kdenlive to 25.08.2`). Pull requests must update both `PKGBUILD` and `.SRCINFO`, attach CI logs, and link upstream releases or issues. Ensure GitHub Actions workflows succeed before requesting review.

## Security & Configuration Tips
Store AUR SSH keys and tokens inside repository secrets (e.g., `AUR_SSH_KEY`, `AUR_GIT_URL`) and rotate them quarterly. Never print secrets in scripts—use environment files or GitHub Actions secrets. Document any new credentials in `docs/secrets.md`, including rotation steps, so maintainers can audit quickly.
