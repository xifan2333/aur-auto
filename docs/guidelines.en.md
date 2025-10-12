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

## CI/CD Automation
GitHub Actions workflows automate upstream monitoring, package building, and AUR publishing. Two workflows handle the complete automation pipeline.

### Workflows Overview
- **Monitor Upstream** (`monitor-upstream.yml`): Scheduled daily (00:00 UTC) to detect new releases via `scripts/update-package.sh`. Regenerates README with updated versions via `scripts/build-readme.sh`. Commits all changes to trigger build workflow.
- **Build and Publish** (`build-and-publish.yml`): Triggered by PKGBUILD/SRCINFO changes. Uses mature GitHub Actions for all operations:
  - Build/validation: [heyhusen/archlinux-package-action](https://github.com/heyhusen/archlinux-package-action) v2
  - AUR publishing: [KSXGitHub/github-actions-deploy-aur](https://github.com/KSXGitHub/github-actions-deploy-aur) v2.7.0

### GitHub Secrets Configuration
Configure secrets in repository Settings → Secrets and variables → Actions:

**Required**:
- `AUR_SSH_KEY`: Private SSH key for AUR authentication. Generate with `ssh-keygen -t rsa -b 4096 -C "aur@github-actions"`, then add the public key to your AUR account SSH settings at https://aur.archlinux.org/account/.

### Manual Workflow Triggers
Both workflows support manual execution via workflow_dispatch:

**Monitor Upstream**:
- Navigate to Actions → Monitor Upstream Releases → Run workflow
- Parameters: `package` (specific package or empty for all), `force` (force update checkbox)

**Build and Publish**:
- Navigate to Actions → Build and Publish to AUR → Run workflow
- Parameters: `package` (required), `skip_publish` (dry-run checkbox)

### Build Environment
Workflows run on `ubuntu-latest` runners and use containerized Arch Linux environments via GitHub Actions. All package operations (makepkg, namcap, AUR publishing) are handled by mature, community-maintained actions with automatic environment setup.

### Troubleshooting Workflows
- **Build failures**: Check Actions logs for makepkg/namcap output. The archlinux-package-action automatically runs `makepkg -s --noconfirm` and validates with namcap. Test locally with `makepkg --syncdeps --cleanbuild`.
- **SSH authentication errors**: Verify `AUR_SSH_KEY` secret configured correctly (must be RSA private key), public key added to AUR account. Test locally: `ssh -T aur@aur.archlinux.org`.
- **AUR publish errors**: Check publish step logs for details. The github-actions-deploy-aur action automatically handles git operations, SSH setup, and file copying. Ensure PKGBUILD and .SRCINFO are valid.
- **No updates detected**: Check `scripts/update-package.sh` output, verify upstream.sh hooks working. Test manually: `./scripts/update-package.sh <package>`.
- **namcap validation fails**: Build action runs namcap on both PKGBUILD and built packages. Review logs, fix issues locally before pushing.

### Artifact Retention
- Build packages (`*.pkg.tar.zst`): 90 days retention
- Build logs and source directory: 30 days retention
- Download from Actions → Workflow run → Artifacts section
