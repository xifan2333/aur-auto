# 仓库规范（中文）

[English Version](guidelines.en.md)

## 项目结构与模块组织
本仓库用于自动化维护 AUR 软件包：负责检测上游新版本、重新构建并推送到 AUR。GitHub Actions 工作流位于 `.github/workflows/`：`monitor-upstream.yml` 用于定时检测，`build-and-publish.yml` 负责构建和发布。通用脚本集中在 `scripts/`，编排逻辑由 `update-package.sh` 负责，后续的共享函数会放在 `scripts/lib/`。每个软件包在 `pkgs/<包名>/` 下维护自己的 `PKGBUILD`、`.SRCINFO` 以及对应的 `upstream.sh`。

## 构建与测试命令
如需本地操作，可执行 `source scripts/env.sh`（若存在）并使用 `./scripts/<脚本名>.sh`。常见的本地检查包括：
- `scripts/update-package.sh kdenlive-appimage-pure`：检测上游版本并刷新 `PKGBUILD` 与 `.SRCINFO`。
- `makepkg --syncdeps --cleanbuild`：在本地执行可复现构建。
- `namcap PKGBUILD`、`namcap *.pkg.tar.zst`：静态质量检查。
- `extra-x86_64-build`：使用官方 clean chroot 验证，与 AUR 工具链保持一致。

## 代码风格与命名
Shell 脚本统一使用 Bash，开头加上 `set -euo pipefail`，并采用两个空格缩进。若有 Python 辅助脚本，需遵循 `black` 和 `isort` 的格式，并为公共函数添加类型注解。目录与 Shell 文件推荐使用全小写加短横线；Python 模块则使用 snake_case。请复用 `scripts/lib/` 中的日志工具，保持 CI 输出风格一致。

## 测试规范
发布前必须运行 `makepkg --syncdeps --cleanbuild`，并保证 `namcap` 无严重问题。修复缺陷时务必增加回归测试；自动化脚本可酌情加入 bats/shunit2 等基础测试。CI 需要在干净 chroot 中构建，完成 QA 后上传构建产物与日志，方便审阅。

## 提交与合并规范
提交信息遵循 Conventional Commits（如 `feat:`、`fix:`、`ci:`），并在标题中注明上游版本号（示例：`fix: bump kdenlive to 25.08.2`）。PR 必须同时更新 `PKGBUILD` 与 `.SRCINFO`，附上 CI 日志，并关联上游发布或问题链接。确保 GitHub Actions 全部通过后再请求评审。

## 安全与配置提示
AUR 的 SSH 密钥和令牌应存储在仓库的 Secrets（如 `AUR_SSH_KEY`）中，并建议按季度轮换。脚本中禁止直接输出敏感信息，可通过环境文件或 Actions Secrets 注入。若新增凭据，请记录在 `docs/secrets.md`，包含轮换流程，方便维护人员审计。

## CI/CD 自动化
GitHub Actions 工作流自动化了上游监控、软件包构建和 AUR 发布。两个工作流处理完整的自动化流程。

### 工作流概述
- **Monitor Upstream**（`monitor-upstream.yml`）：每日定时（UTC 00:00）通过 `scripts/update-package.sh` 检测新版本。通过 `scripts/build-readme.sh` 重新生成 README 并更新版本信息。提交所有更改以触发构建工作流。
- **Build and Publish**（`build-and-publish.yml`）：由 PKGBUILD/SRCINFO 变更触发。使用成熟的 GitHub Actions 完成所有操作：
  - 构建/验证：[heyhusen/archlinux-package-action](https://github.com/heyhusen/archlinux-package-action) v2
  - AUR 发布：[KSXGitHub/github-actions-deploy-aur](https://github.com/KSXGitHub/github-actions-deploy-aur) v2.7.0

### GitHub Secrets 配置
在仓库的 Settings → Secrets and variables → Actions 中配置：

**必需**：
- `AUR_SSH_KEY`：用于 AUR 身份验证的私钥。使用 `ssh-keygen -t rsa -b 4096 -C "aur@github-actions"` 生成，然后在 https://aur.archlinux.org/account/ 添加公钥。

### 手动触发工作流
两个工作流都支持通过 workflow_dispatch 手动执行：

**Monitor Upstream**：
- 导航到 Actions → Monitor Upstream Releases → Run workflow
- 参数：`package`（指定包或留空检查所有包）、`force`（强制更新复选框）

**Build and Publish**：
- 导航到 Actions → Build and Publish to AUR → Run workflow
- 参数：`package`（必需）、`skip_publish`（干运行复选框）

### 构建环境
工作流运行在 `ubuntu-latest` runner 上，通过 GitHub Actions 使用容器化的 Arch Linux 环境。所有软件包操作（makepkg、namcap、AUR 发布）由成熟的社区维护 actions 处理，自动完成环境设置。

### 工作流故障排除
- **构建失败**：查看 Actions 日志中的 makepkg/namcap 输出。archlinux-package-action 自动运行 `makepkg -s --noconfirm` 并使用 namcap 验证。本地测试：`makepkg --syncdeps --cleanbuild`。
- **SSH 认证错误**：验证 `AUR_SSH_KEY` secret 配置正确（必须是 RSA 私钥），公钥已添加到 AUR 账户。本地测试：`ssh -T aur@aur.archlinux.org`。
- **AUR 发布错误**：检查发布步骤日志。github-actions-deploy-aur action 自动处理 git 操作、SSH 设置和文件复制。确保 PKGBUILD 和 .SRCINFO 有效。
- **未检测到更新**：检查 `scripts/update-package.sh` 输出，验证 upstream.sh 钩子是否正常工作。手动测试：`./scripts/update-package.sh <包名>`。
- **namcap 验证失败**：构建 action 会在 PKGBUILD 和构建的包上运行 namcap。查看日志，在推送前本地修复问题。

### 产物保留
- 构建包（`*.pkg.tar.zst`）：90 天保留期
- 构建日志和源码目录：30 天保留期
- 从 Actions → Workflow run → Artifacts 部分下载
