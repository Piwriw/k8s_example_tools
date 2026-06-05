# setup-packages

跨发行版的 Go / Python 一键安装脚本集合。

> 脚本特性：
> - 强健的错误处理（`set -euo pipefail`）和临时文件自动清理
> - 自动识别系统架构（`amd64` / `arm64`），不支持时直接退出并提示
> - 版本号格式校验，缺参或非法参数会打印 `Usage`
> - 环境变量写入 `/etc/profile.d/*.sh`，**安装完成后需手动 `source` 或重新登录**才会立即生效

---

## Install Go

支持 amd64 / arm64 Linux。

### 方式一：下载后执行

```bash
curl -fL https://raw.githubusercontent.com/Piwriw/k8s_example_tools/master/setup-packages/go/setup-linux.sh -o setup-go.sh
bash setup-go.sh 1.19          # 把 1.19 换成你想要的版本，例如 1.21.4
```

### 方式二：在线执行

```bash
curl -fL https://raw.githubusercontent.com/Piwriw/k8s_example_tools/master/setup-packages/go/setup-linux.sh | bash -s 1.19
```

### 验证

```bash
source /etc/profile.d/go.sh
go version
```

---

## Install Python

支持 RHEL/CentOS（`yum`）、Fedora（`dnf`）、Ubuntu/Debian（`apt`）。

### 方式一：下载后执行

```bash
wget https://raw.githubusercontent.com/Piwriw/k8s_example_tools/master/setup-packages/python/setup-linux.sh
bash setup-linux.sh 3.9.0       # 把 3.9.0 换成你想要的版本，例如 3.11.7
```

### 方式二：在线执行

```bash
curl -fSL https://raw.githubusercontent.com/Piwriw/k8s_example_tools/master/setup-packages/python/setup-linux.sh | bash -s 3.9.0
```

### 验证

```bash
source /etc/profile.d/python3.sh
python3 -V
pip3 -V
```

---

## 用法

```
bash setup-linux.sh <version>
```

- `version` 必填，需符合 `X.Y` 或 `X.Y.Z` 格式（如 `1.19`、`3.9.0`）
- 缺参时会自动打印 `Usage`
- 脚本需要在具有 `sudo` 权限的账户下运行

## 注意事项

1. **环境变量不会自动生效**：脚本会把 `GOROOT` / `PATH` / `GOPROXY` 写入 `/etc/profile.d/*.sh`，请执行 `source /etc/profile.d/<name>.sh` 或重新登录。
2. **网络要求**：脚本默认从 `studygolang.com`（Go）和 `mirrors.aliyun.com`（Python）下载，如需替换镜像请修改脚本内 `URL` 变量。
3. **系统要求**：Linux x86_64 / arm64；需要预装 `curl`（Go 脚本）和 `sudo`（两个脚本都需要）。
4. **Python 编译依赖**：脚本会自动安装 `gcc / make / zlib-devel / libffi-devel` 等编译依赖（按发行版选用 `apt` / `dnf` / `yum`）。
