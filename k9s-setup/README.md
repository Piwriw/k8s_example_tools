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
