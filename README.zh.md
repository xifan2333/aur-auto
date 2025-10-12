<!-- 该文件由 docs/readme.zh.template.md 渲染而来，执行 scripts/build-readme.sh 生成。 -->

# aur-auto

[![AUR 维护者](https://img.shields.io/badge/AUR-xifan-1793D1?logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages?SeB=m&K=xifan)

使用 GitHub Actions 自动维护 Arch User Repository 软件包的工具集。

## 项目概览
- 每个包通过 `pkgs/<pkgname>/upstream.sh` 钩子检测上游新版本。
- 自动更新 PKGBUILD 元数据，在 clean chroot 中构建并推送至 AUR。
- 为贡献者与维护者提供双语文档。

## 维护者
- xifan `<xifan2333@gmail.com>`

## 文档
- 仓库规范：[English](docs/guidelines.en.md) · [中文](docs/guidelines.zh.md)
- 打包流程：[English](docs/packaging.en.md) · [中文](docs/packaging.zh.md)
- README (English Version): [docs/readme.en.md](docs/readme.en.md)

## 软件包
| Package | Description | Upstream | Version | Build Status |
| --- | --- | --- | --- | --- |
| `kdenlive-appimage-pure` | A non-linear video editor for Linux using the MLT video framework (AppImage build) | `Kdenlive` | 25.08.2 | [![Build Status](https://img.shields.io/github/actions/workflow/status/xifan/aur-auto/release.yml?branch=main&logo=github&label=build)](https://github.com/xifan/aur-auto/actions/workflows/release.yml) |

文档或元数据更新后，请运行 `scripts/build-readme.sh` 重新生成 README。
