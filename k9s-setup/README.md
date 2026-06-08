# k9s-setup
通过下载 GitHub Release 二进制的方式安装 K9s(Kubernetes 集群管理 TUI 工具)。
官方仓库: https://github.com/derailed/k9s

## Info
支持平台:
- OS: Linux / Darwin (macOS)
- ARCH: amd64 (x86_64) / arm64 (aarch64)

下载源:
- `https://github.com/derailed/k9s/releases/download/<version>/k9s_<os>_<arch>.tar.gz`

下载行为:
- 交互式终端下会显示 curl 进度条
- 非交互式环境(如重定向、管道)自动静默下载

## 环境变量
| 变量名          | 默认值            | 说明                          |
| --------------- | ----------------- | ----------------------------- |
| `K9S_VERSION`   | `latest`          | 指定安装版本(如 `v0.32.5`)   |
| `INSTALL_DIR`   | `/usr/local/bin`  | 二进制安装路径                |

## Deploy
```bash
# 给脚本执行权限
chmod +x k9s-install.sh

# 安装最新稳定版
sudo ./k9s-install.sh

# 安装指定版本
sudo K9S_VERSION=v0.32.5 ./k9s-install.sh

# 安装到自定义目录(无需 sudo)
INSTALL_DIR=$HOME/bin ./k9s-install.sh
```

安装完成后可直接执行 `k9s` 启动 TUI。

## 环境变量（离线部署）

| 变量名          | 默认值            | 适用脚本              | 说明                          |
| --------------- | ----------------- | --------------------- | ----------------------------- |
| `K9S_VERSION`   | `latest`          | k9s-download.sh       | 指定下载版本(如 `v0.32.5`)   |
| `K9S_ARCH`      | 当前机器架构      | k9s-download.sh / tag | 指定架构(`amd64`/`arm64`)    |
| `INSTALL_DIR`   | `/usr/local/bin`  | k9s-offline-install.sh| 二进制安装路径                |

## 离线部署

适用于内网无法访问 GitHub 的服务器环境。

### 步骤1：在有网机器下载

```bash
# 默认最新版，自动检测架构
chmod +x k9s-download.sh
./k9s-download.sh

# 指定版本和架构（下载机器可能与目标机器架构不同）
./k9s-download.sh -v v0.32.5 -a amd64
./k9s-download.sh -v v0.32.5 -a arm64
```

### 步骤2：打包交付物

```bash
chmod +x k9s-tag.sh

# 打包 amd64 离线包
./k9s-tag.sh -a amd64

# 打包 arm64 离线包
./k9s-tag.sh -a arm64
```

输出文件: `k9s-offline-<arch>.tar.gz`

### 步骤3：在离线机器安装

```bash
# 拷贝到离线机器
scp k9s-offline-amd64.tar.gz offline-server:/tmp/

# 在离线机器上解压并安装
cd /tmp
tar xzf k9s-offline-amd64.tar.gz
sudo ./k9s-offline-install.sh

# 或指定离线包路径
sudo ./k9s-offline-install.sh -p k9s-offline-amd64.tar.gz

# 安装到自定义目录
sudo INSTALL_DIR=$HOME/bin ./k9s-offline-install.sh
```
