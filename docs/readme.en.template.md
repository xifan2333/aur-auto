<!-- This file is generated from docs/readme.en.template.md. Run scripts/build-readme.sh to regenerate. -->

# aur-auto

[![AUR Maintainer](https://img.shields.io/badge/AUR-{{AUR_USER}}-1793D1?logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages?SeB=m&K={{AUR_USER}})

Automation toolkit for maintaining Arch User Repository packages with GitHub Actions.

## Overview
- Detect upstream releases per package by calling dedicated hooks in `pkgs/<pkgname>/upstream.sh`.
- Regenerate PKGBUILD metadata, build packages in clean chroots, and publish to AUR.
- Provide bilingual documentation for contributors and maintainers.

## Maintainers
- {{AUR_USER}} `<{{AUR_EMAIL}}>`

## Documentation
- Repository Guidelines: [English](docs/guidelines.en.md) · [中文](docs/guidelines.zh.md)
- Packaging Workflow: [English](docs/packaging.en.md) · [中文](docs/packaging.zh.md)
- README (中文版本): [docs/readme.zh.md](docs/readme.zh.md)

## Packages
{{PACKAGE_TABLE}}

Regenerate this README after documentation or metadata changes with `scripts/build-readme.sh`.
