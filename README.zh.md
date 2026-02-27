<!-- 该文件由 scripts/build-readme.sh 自动生成，请勿手动编辑。 -->

# aur-auto

[![AUR 维护者](https://img.shields.io/badge/AUR-xifan-1793D1?logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages?SeB=m&K=xifan)

使用 GitHub Actions 自动维护 Arch User Repository 软件包的工具集。

## 项目概览
- 每个包通过 `pkgs/<pkgname>/upstream.sh` 钩子检测上游新版本。
- 自动更新 PKGBUILD 元数据，在 clean chroot 中构建并推送至 AUR。

## 维护者
- xifan `<xifan2333@gmail.com>`

## 软件包
| Package | Description | Upstream | Version | Build Status |
| --- | --- | --- | --- | --- |
| `hapi-git` | App for agentic coding - access coding agent anywhere (Built from source) | `hapi-git` | 0.15.3 | [![Build Status](https://img.shields.io/github/actions/workflow/status/xifan2333/aur-auto/build-and-publish.yml?branch=main&logo=github&label=build)](https://github.com/xifan2333/aur-auto/actions/workflows/build-and-publish.yml) |
| `kdenlive-appimage-pure` | A non-linear video editor for Linux using the MLT video framework (AppImage build) | `kdenlive` | 25.12.2 | [![Build Status](https://img.shields.io/github/actions/workflow/status/xifan2333/aur-auto/build-and-publish.yml?branch=main&logo=github&label=build)](https://github.com/xifan2333/aur-auto/actions/workflows/build-and-publish.yml) |
| `roxybrowser-bin` | Premier Antidetect Browser - Streamline Your Workflow Effortlessly (Unofficial Community Package) | `roxybrowser` | 3.7.2 | [![Build Status](https://img.shields.io/github/actions/workflow/status/xifan2333/aur-auto/build-and-publish.yml?branch=main&logo=github&label=build)](https://github.com/xifan2333/aur-auto/actions/workflows/build-and-publish.yml) |
| `unibarrage-bin` | High-performance real-time proxy tool to unify live barrage data collection across multiple streaming platforms | `unibarrage` | 1.0.1 | [![Build Status](https://img.shields.io/github/actions/workflow/status/xifan2333/aur-auto/build-and-publish.yml?branch=main&logo=github&label=build)](https://github.com/xifan2333/aur-auto/actions/workflows/build-and-publish.yml) |

文档或元数据更新后，请运行 `scripts/build-readme.sh` 重新生成 README。
