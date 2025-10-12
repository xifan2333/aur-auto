<!-- This file is generated from docs/readme.en.template.md. Run scripts/build-readme.sh to regenerate. -->

# aur-auto

[![AUR Maintainer](https://img.shields.io/badge/AUR-xifan-1793D1?logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages?SeB=m&K=xifan)

Automation toolkit for maintaining Arch User Repository packages with GitHub Actions.

## Overview
- Detect upstream releases per package by calling dedicated hooks in `pkgs/<pkgname>/upstream.sh`.
- Regenerate PKGBUILD metadata, build packages in clean chroots, and publish to AUR.
- Provide bilingual documentation for contributors and maintainers.

## Maintainers
- xifan `<xifan2333@gmail.com>`

## Documentation
- Repository Guidelines: [English](docs/guidelines.en.md) · [中文](docs/guidelines.zh.md)
- Packaging Workflow: [English](docs/packaging.en.md) · [中文](docs/packaging.zh.md)
- README (中文版本): [docs/readme.zh.md](docs/readme.zh.md)

## Packages
| Package | Description | Upstream | Version | Build Status |
| --- | --- | --- | --- | --- |
| `kdenlive-appimage-pure` | A non-linear video editor for Linux using the MLT video framework (AppImage build) | `Kdenlive` | 25.08.2 | [![Build Status](https://img.shields.io/github/actions/workflow/status/xifan/aur-auto/release.yml?branch=main&logo=github&label=build)](https://github.com/xifan/aur-auto/actions/workflows/release.yml) |

Regenerate this README after documentation or metadata changes with `scripts/build-readme.sh`.
