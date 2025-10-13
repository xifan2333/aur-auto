# 打包流程（中文）

[English Version](packaging.en.md)

## 仓库布局
- `pkgs/<包名>/PKGBUILD`：标准打包脚本。
- `pkgs/<包名>/.SRCINFO`：通过 `makepkg --printsrcinfo` 重新生成。
- `pkgs/<包名>/upstream.sh`：定义包的更新钩子，实现自动化。
- `scripts/update-package.sh`：通用框架脚本，调用各包钩子。
- `.github/workflows/monitor-upstream.yml`：定时检测上游版本更新。
- `.github/workflows/build-and-publish.yml`：自动构建并发布到 AUR。

补丁或启动脚本请放在对应包目录下。AppImage 的桌面集成（包装脚本、图标、`.desktop` 文件）应在 `package()` 中生成，不要直接提交二进制资产。

## 自动更新流程
1. 执行 `scripts/update-package.sh <包名>` 检测上游新版本。
2. 框架调用 `pkg_detect_latest()` 获取最新版本号。
3. 框架调用 `pkg_get_update_params(version)` 获取更新参数（包自己下载和计算校验和）。
4. 框架调用 `pkg_update_files()` 更新 PKGBUILD（包完全控制更新逻辑）。
5. 脚本输出版本变更（`old -> new`）。需要强制刷新时可使用 `--force`。

### upstream.sh 接口说明

框架会依次调用以下函数（包必须实现）：

**必需函数**：

- `pkg_detect_latest()`
  - 返回：最新版本号字符串

- `pkg_get_update_params(version)`
  - 参数：`version` - 最新版本号
  - 返回：`"<url> <filename> <pkgver> <hash_algo> <checksum>"`（空格分隔）
    - `url`: 下载链接
    - `filename`: 文件名
    - `pkgver`: PKGBUILD 中的版本号（可能与 version 不同）
    - `hash_algo`: 校验算法（sha256, sha512, b2, md5 等）
    - `checksum`: 校验和值

- `pkg_update_files(url, filename, pkgver, hash_algo, checksum)`
  - 参数：从 `pkg_get_update_params` 返回的5个值
  - 功能：更新 PKGBUILD 和 .SRCINFO

**设计原则**：
- 框架只做协调，不控制业务逻辑
- 包自己决定下载、校验算法、版本格式
- 统一接口格式，包完全自主

## 手动验证清单
- `makepkg --cleanbuild --syncdeps`
- `namcap PKGBUILD`、`namcap *.pkg.tar.zst`
- 安装测试：`sudo pacman -U kdenlive-appimage-pure-*.pkg.tar.zst`，确认应用与图标可用。
- 清理：`rm -rf src pkg *.pkg.tar.* *.AppImage`

## 发布前检查
- 提交时务必包含 `PKGBUILD` 与 `.SRCINFO`。
- PR 或 CI 需要附上构建/测试日志。
- 若上游目录结构变化，应及时更新 `upstream.sh` 的解析逻辑，并输出明确错误信息，便于 CI 快速定位问题。
