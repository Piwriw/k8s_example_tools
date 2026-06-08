# k9s-setup 离线部署设计

## 背景

现有 `k9s-setup/k9s-install.sh` 是在线安装方式，从 GitHub Release 下载二进制包并安装。
内网服务器无法访问 GitHub，需要离线部署能力。

## 目标

- 在有网机器上预下载 k9s 二进制包
- 打包为离线交付 tar.gz
- 在离线内网服务器上安装

## 方案：三脚本分离模式

与项目中 `docker-bin-setup-offline`、`prometheus-offline` 等现有离线目录的模式保持一致：
download（获取资源）+ install（部署安装）+ tag（打包交付）三脚本分离。

### 目录结构

```
k9s-setup/
├── README.md              # 更新，补充离线部署说明
├── k9s-install.sh         # 保留，在线安装（不动）
├── k9s-download.sh        # 新增，在有网环境下载二进制
├── k9s-offline-install.sh # 新增，在离线环境安装
├── k9s-tag.sh             # 新增，打包为离线交付物
└── packages/              # 新增，存放下载的二进制包（不提交 git）
    └── README.md           # 说明如何获取二进制包
```

### 脚本职责

#### k9s-download.sh（有网机器执行）

- 检测/接收版本参数（默认 `latest`，从 GitHub API 解析）
- 检测/接收架构参数（`amd64` / `arm64`，默认当前机器架构）
- 从 GitHub Release 下载 `k9s_Linux_<arch>.tar.gz`
- 解压提取 `k9s` 二进制到 `packages/` 目录
- 仅支持 Linux 目标（离线部署目标是 Linux 服务器）
- 打印下载结果（版本、架构、文件路径）
- 交互式终端显示 curl 进度条，非交互式静默下载（与 k9s-install.sh 保持一致）

#### k9s-offline-install.sh（离线机器执行）

- 从解压后的目录中查找 `k9s` 二进制
- 安装到 `${INSTALL_DIR}`（默认 `/usr/local/bin`）
- 校验安装结果（`k9s version`）
- 支持 `-p` 参数指定 tar.gz 包路径，自动解压后安装
- 无参数时从当前目录的 `packages/` 查找

#### k9s-tag.sh（打包交付）

- 将 `k9s-offline-install.sh` + `packages/k9s` 打包为 `k9s-offline-<arch>.tar.gz`
- 支持 `amd64` 和 `arm64` 双架构
- 打包文件列表：k9s-offline-install.sh、packages/k9s、packages/README.md

### 使用流程

```bash
# 步骤1：在有网机器上下载
./k9s-download.sh                    # 默认最新版，自动检测架构
./k9s-download.sh -a arm64 -v v0.32.5  # 指定版本和架构

# 步骤2：打包交付物
./k9s-tag.sh                         # 打包为 k9s-offline-amd64.tar.gz
./k9s-tag.sh -a arm64                # 打包为 k9s-offline-arm64.tar.gz

# 步骤3：拷贝到离线机器并安装
scp k9s-offline-amd64.tar.gz offline-server:/tmp/
cd /tmp && tar xzf k9s-offline-amd64.tar.gz
sudo ./k9s-offline-install.sh
```

### 环境变量

| 变量 | 默认值 | 适用脚本 | 说明 |
|------|--------|---------|------|
| `K9S_VERSION` | `latest` | download | 指定版本（如 `v0.32.5`） |
| `K9S_ARCH` | 当前机器架构 | download, offline-install, tag | 指定架构（`amd64`/`arm64`） |
| `INSTALL_DIR` | `/usr/local/bin` | offline-install | 二进制安装路径 |

### 大文件处理

- `packages/` 目录下的二进制包不提交 git
- `.gitignore` 中排除 `packages/k9s` 和 `*.tar.gz` 交付物
- `packages/README.md` 说明如何通过 download 脚本获取二进制包

### 架构检测逻辑

与现有 `k9s-install.sh` 保持一致的检测方式：

```bash
case "$(uname -m)" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
esac
```

download 脚本中此检测用于默认值，可通过 `-a` 参数覆盖（因为下载机器可能是 macOS arm64，
但目标服务器是 Linux amd64）。

### 错误处理

- 所有脚本统一 `set -e`
- download 脚本：curl 下载失败时明确报错，不继续解压
- offline-install 脚本：找不到 k9s 二进制时报错退出
- tag 脚本：packages/ 目录不存在或无 k9s 二进制时报错退出