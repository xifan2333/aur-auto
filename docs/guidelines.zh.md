# 仓库规范（中文）

[English Version](guidelines.en.md)

## 项目结构与模块组织
本仓库用于自动化维护 AUR 软件包：负责检测上游新版本、重新构建并推送到 AUR。GitHub Actions 工作流位于 `.github/workflows/`：`monitor-upstream.yml` 用于定时检测，`release.yml` 负责发布。通用脚本集中在 `scripts/`，编排逻辑由 `update-package.sh` 负责，后续的共享函数会放在 `scripts/lib/`。每个软件包在 `pkgs/<包名>/` 下维护自己的 `PKGBUILD`、`.SRCINFO` 以及对应的 `upstream.sh`。

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
AUR 的 SSH 密钥和令牌应存储在仓库的 Secrets（如 `AUR_SSH_KEY`、`AUR_GIT_URL`）中，并建议按季度轮换。脚本中禁止直接输出敏感信息，可通过环境文件或 Actions Secrets 注入。若新增凭据，请记录在 `docs/secrets.md`，包含轮换流程，方便维护人员审计。
