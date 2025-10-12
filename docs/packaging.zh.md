# 打包流程（中文）

[English Version](packaging.en.md)

## 仓库布局
- `pkgs/<包名>/PKGBUILD`：标准打包脚本。
- `pkgs/<包名>/.SRCINFO`：通过 `makepkg --printsrcinfo` 重新生成。
- `pkgs/<包名>/upstream.sh`：定义包的更新钩子，实现自动化。
- `scripts/update-package.sh`：通用框架脚本，调用各包钩子。

补丁或启动脚本请放在对应包目录下。AppImage 的桌面集成（包装脚本、图标、`.desktop` 文件）应在 `package()` 中生成，不要直接提交二进制资产。

## 自动更新流程
1. 执行 `scripts/update-package.sh <包名>` 检测上游新版本。
2. 包的钩子返回下载地址，框架负责下载并计算新的 SHA256。
3. `pkg_update_files` 写入 `pkgver`、重置 `pkgrel`、更新 `source_x86_64` 与 `sha256sums_x86_64`，然后运行 `makepkg --printsrcinfo > .SRCINFO`。
4. 脚本输出版本变更（`old -> new`）。需要强制刷新时可使用 `--force`。

目前的示例：
- `kdenlive-appimage-pure`：从 KDE 官方下载 AppImage，自动解析最新稳定版。

## 手动验证清单
- `makepkg --cleanbuild --syncdeps`
- `namcap PKGBUILD`、`namcap *.pkg.tar.zst`
- 安装测试：`sudo pacman -U kdenlive-appimage-pure-*.pkg.tar.zst`，确认应用与图标可用。
- 清理：`rm -rf src pkg *.pkg.tar.* *.AppImage`

## 发布前检查
- 提交时务必包含 `PKGBUILD` 与 `.SRCINFO`。
- PR 或 CI 需要附上构建/测试日志。
- 若上游目录结构变化，应及时更新 `upstream.sh` 的解析逻辑，并输出明确错误信息，便于 CI 快速定位问题。
