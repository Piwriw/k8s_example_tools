# setup-scripts-optimization Design

**Date:** 2026-06-05
**Status:** Approved
**Scope:** `setup-packages/go/setup-linux.sh` 与 `setup-packages/python/setup-linux.sh`

## 目标

在不改变对外接口（`bash setup-linux.sh <version>`）的前提下，提升两个安装脚本的**可靠性**与**可读性**，并让 Python 脚本支持 Ubuntu/Debian。

## 通用改造原则

1. **Shebang 统一为** `#!/usr/bin/env bash`。
2. **安全模式**：`set -euo pipefail`，并在 `set` 之后重置 `IFS=$'\n\t'`。
3. **统一日志函数**：`log_info` / `log_warn` / `log_error`，全部走 stderr/stdout 区分。
4. **临时目录**：`mktemp -d` + `trap cleanup EXIT`，避免污染调用方目录。
5. **架构检测**：`detect_arch()` 单独函数，未识别时 `exit 1` 并给出明确提示。
6. **参数校验**：版本号必填，非空校验，缺参时打印 `Usage` 后 `exit 1`。
7. **变量全加引号**：`"$var"` 而非 `$var`。
8. **下载稳健**：`curl -fL`（`-f` 失败立即退出，`-L` 跟随重定向），失败时清理半截文件。
9. **环境变量写法**：写到 `/etc/profile.d/<name>.sh`，不再追加 `/etc/profile`；不调用无效的 `source`。
10. **保持接口稳定**：用户仍可 `bash setup-linux.sh <version>` 运行。

## go/setup-linux.sh 改造点

| # | 现状 | 改造后 |
|---|------|--------|
| 1 | 仅 `set -e` | `set -euo pipefail` + `IFS=$'\n\t'` |
| 2 | 无参数校验，`$1` 为空时下载空版本 | 校验 `VERSION` 非空，否则 `Usage` + `exit 1` |
| 3 | 架构不支持时仅 echo 不退出 | `exit 1` |
| 4 | `echo "当前系统Centos为 AMD64"` 错别字 | 改为 `当前系统架构为 AMD64` |
| 5 | `source /etc/profile` 在子 shell 无效 | 删除；改为写入 `/etc/profile.d/go.sh` |
| 6 | `echo "export PATH=$PATH:$GOROOT/bin"` 中 `$GOROOT` 为空 | 直接写死 `/usr/local/go/bin` |
| 7 | 下载到当前目录 | `mktemp -d`，退出时 `trap cleanup` |
| 8 | `curl -OL` 不会因 HTTP 错误退出 | `curl -fLO` |
| 9 | GOPROXY/GO111MODULE 仅在脚本内 export | 追加到 `/etc/profile.d/go.sh`，永久生效 |

新增函数：`log_info/log_warn/log_error`、`detect_arch`、`check_curl`、`download_go`、`extract_go`、`write_profile`、`print_summary`。

## python/setup-linux.sh 改造点

| # | 现状 | 改造后 |
|---|------|--------|
| 1 | `install_dependencies` 写死 `yum` | 新增 `detect_os` 识别 `yum` / `apt`；分支安装 |
| 2 | `yum` 未加 `sudo`（与 `configure` 不一致） | 全部 `sudo` |
| 3 | 无架构检测 | 新增 `detect_arch`（与 Go 脚本保持一致） |
| 4 | `source ~/.bashrc` 在子 shell 无效 | 改为追加到 `~/.bashrc` 后提示用户 `source` 或重新登录 |
| 5 | 无 Usage 提示 | 缺参数时打印 `Usage` |
| 6 | Shebang 为 `#!/bin/bash` | 改为 `#!/usr/bin/env bash`（与其他脚本一致） |
| 7 | 无 `mktemp` 之外的网络/磁盘检查 | 下载前 `df` 检查可用空间（可省略，仅在 prompt 中提示） |

保留原有：trap 清理、log/error 函数、参数解析、版本校验、pip 镜像配置、版本一致性检查。

新增/修改函数：`detect_os`、`install_dependencies`（apt 分支）、`verify_disk_space`（可选）。

## 风险与回退

- **风险**：原 `python` 脚本有 `set -euo pipefail` + trap，本就健壮，改造以"等价替换"为主。
- **回退**：所有改动都在新版本内完成；`git log` 可直接 diff 旧版本回退。
- **测试**：因脚本涉及下载/编译，无法在 CI 中端到端验证；至少做 `bash -n` 与 `shellcheck` 静态检查。

## 不在范围内

- 不增加 `--uninstall` / `--dry-run` 等新接口。
- 不引入颜色输出、进度条。
- 不改 README 的命令示例（接口不变）。
