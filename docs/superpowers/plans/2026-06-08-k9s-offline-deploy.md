# k9s 离线部署实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 k9s-setup 新增离线部署能力，三脚本分离模式（download + offline-install + tag）

**Architecture:** 在有网机器用 k9s-download.sh 下载二进制到 packages/ 目录，用 k9s-tag.sh 打包为 k9s-offline-<arch>.tar.gz 交付物，在离线机器用 k9s-offline-install.sh 安装。与项目已有离线目录（docker-bin-setup-offline 等）模式一致。

**Tech Stack:** Bash shell scripts, curl, tar

---

### Task 1: 创建 packages 目录和 README.md

**Files:**
- Create: `k9s-setup/packages/README.md`

- [ ] **Step 1: 创建 packages 目录**

```bash
mkdir -p k9s-setup/packages
```

- [ ] **Step 2: 写 packages/README.md**

```markdown
此目录存放 k9s 二进制文件，用于离线部署安装。

## 获取二进制

运行下载脚本获取 k9s 二进制：

```bash
# 在有网机器上执行
chmod +x k9s-download.sh

# 默认最新版，自动检测架构
./k9s-download.sh

# 指定版本和架构
./k9s-download.sh -v v0.32.5 -a amd64
./k9s-download.sh -v v0.32.5 -a arm64
```

下载完成后 `packages/k9s` 即为目标二进制文件。

注意：此目录下的 k9s 二进制不提交到 git 仓库。
```

写入文件 `k9s-setup/packages/README.md`。

- [ ] **Step 3: 更新 .gitignore 排除 packages/k9s**

`.gitignore` 中已有 `*.tar.gz` 规则，只需新增排除 k9s 二进制文件：

```
k9s-setup/packages/k9s
```

修改 `/.gitignore`，在末尾追加此行。

- [ ] **Step 4: Commit**

```bash
git add k9s-setup/packages/README.md .gitignore
git commit -m "feat(k9s): add packages directory and gitignore for offline deploy"
```

---

### Task 2: 创建 k9s-download.sh

**Files:**
- Create: `k9s-setup/k9s-download.sh`

这是在有网环境执行的下载脚本。参考现有 `k9s-install.sh` 的版本解析和下载逻辑，但增加参数解析、固定 Linux 目标平台、将二进制提取到 packages/ 目录。

- [ ] **Step 1: 编写 k9s-download.sh**

```bash
#!/bin/bash
# 在有网环境下载 k9s 二进制文件，用于离线部署
# K9s 官方仓库: https://github.com/derailed/k9s

set -e

# 默认参数
K9S_VERSION="${K9S_VERSION:-latest}"
K9S_ARCH="${K9S_ARCH:-}"

# 脚本所在目录（packages 相对于脚本位置）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 解析命令行参数
while getopts "v:a:" opt; do
  case "${opt}" in
    v) K9S_VERSION="${OPTARG}" ;;
    a) K9S_ARCH="${OPTARG}" ;;
    *) echo "用法: $0 [-v 版本号] [-a 架构(amd64/arm64)]"; exit 1 ;;
  esac
done

# 架构检测（默认取当前机器架构，可通过 -a 覆盖）
if [ -z "${K9S_ARCH}" ]; then
  case "$(uname -m)" in
    x86_64) K9S_ARCH="amd64" ;;
    aarch64|arm64) K9S_ARCH="arm64" ;;
    *)
      echo "不支持的架构: $(uname -m)"
      echo "请通过 -a 参数指定目标架构 (amd64/arm64)"
      exit 1
      ;;
  esac
fi

# 校验架构参数
case "${K9S_ARCH}" in
  amd64|arm64) ;;
  *)
    echo "不支持的架构: ${K9S_ARCH}，仅支持 amd64 或 arm64"
    exit 1
    ;;
esac

# 离线部署目标为 Linux 服务器，固定 OS 为 Linux
TARGET_OS="linux"

# 解析版本号（latest 则从 GitHub API 获取最新 release tag）
if [ "${K9S_VERSION}" = "latest" ]; then
  K9S_VERSION="$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest \
    | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
fi

if [ -z "${K9S_VERSION}" ]; then
  echo "无法解析 K9s 版本号"
  exit 1
fi

VERSION_NO_V="${K9S_VERSION#v}"
TARBALL="k9s_${TARGET_OS}_${K9S_ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${TARBALL}"

echo ">>> 准备下载 K9s ${K9S_VERSION} (${TARGET_OS}/${K9S_ARCH})"
echo ">>> 下载地址: ${DOWNLOAD_URL}"

# 创建 packages 目录
PACKAGES_DIR="${SCRIPT_DIR}/packages"
mkdir -p "${PACKAGES_DIR}"

# 创建临时目录并下载
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# 交互式终端下显示进度条，非交互式环境静默下载
if [ -t 2 ]; then
  curl -fL --progress-bar "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
else
  curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
fi

# 解压并提取 k9s 二进制到 packages 目录
tar -xzf "${TMP_DIR}/${TARBALL}" -C "${TMP_DIR}" k9s
cp "${TMP_DIR}/k9s" "${PACKAGES_DIR}/k9s"
chmod +x "${PACKAGES_DIR}/k9s"

echo ">>> K9s ${K9S_VERSION} (${TARGET_OS}/${K9S_ARCH}) 已下载到 ${PACKAGES_DIR}/k9s"
echo ">>> 文件大小: $(du -h "${PACKAGES_DIR}/k9s" | cut -f1)"
echo ""
echo "下一步: 运行 k9s-tag.sh 打包为离线交付物"
echo "  ./k9s-tag.sh -a ${K9S_ARCH}"
```

写入文件 `k9s-setup/k9s-download.sh`。

- [ ] **Step 2: 设置执行权限并提交**

```bash
chmod +x k9s-setup/k9s-download.sh
git add k9s-setup/k9s-download.sh
git commit -m "feat(k9s): add k9s-download.sh for offline binary download"
```

---

### Task 3: 创建 k9s-offline-install.sh

**Files:**
- Create: `k9s-setup/k9s-offline-install.sh`

这是在离线环境执行的安装脚本。参考 `docker-bin-setup-offline/setup.sh` 的简洁安装模式。

- [ ] **Step 1: 编写 k9s-offline-install.sh**

```bash
#!/bin/bash
# 在离线环境安装 k9s 二进制
# K9s 官方仓库: https://github.com/derailed/k9s

set -e

# 安装路径，默认为 /usr/local/bin，可通过环境变量 INSTALL_DIR 覆盖
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 解析命令行参数
TARBALL_PATH=""
while getopts "p:" opt; do
  case "${opt}" in
    p) TARBALL_PATH="${OPTARG}" ;;
    *) echo "用法: $0 [-p 离线包路径(k9s-offline-<arch>.tar.gz)]"; exit 1 ;;
  esac
done

# 如果指定了 tar.gz 包路径，先解压
if [ -n "${TARBALL_PATH}" ]; then
  echo ">>> 解压离线包: ${TARBALL_PATH}"

  # 校验文件存在
  if [ ! -f "${TARBALL_PATH}" ]; then
    echo "离线包不存在: ${TARBALL_PATH}"
    exit 1
  fi

  # 解压到脚本所在目录（tar 包内结构为 packages/k9s + k9s-offline-install.sh）
  tar -xzf "${TARBALL_PATH}" -C "${SCRIPT_DIR}"
fi

# 查找 k9s 二进制
K9S_BIN="${SCRIPT_DIR}/packages/k9s"

if [ ! -f "${K9S_BIN}" ]; then
  echo "找不到 k9s 二进制文件: ${K9S_BIN}"
  echo "请确保已解压离线包或 packages/k9s 文件存在"
  exit 1
fi

echo ">>> 准备安装 k9s 到 ${INSTALL_DIR}"

# 安装 k9s 二进制
install -m 0755 "${K9S_BIN}" "${INSTALL_DIR}/k9s"

echo ">>> k9s 已安装到 ${INSTALL_DIR}/k9s"

# 校验安装
if command -v k9s >/dev/null 2>&1; then
  k9s version --short 2>/dev/null || "${INSTALL_DIR}/k9s" version
else
  echo ">>> 安装校验: 请确认 ${INSTALL_DIR} 在 PATH 中"
fi
```

写入文件 `k9s-setup/k9s-offline-install.sh`。

- [ ] **Step 2: 设置执行权限并提交**

```bash
chmod +x k9s-setup/k9s-offline-install.sh
git add k9s-setup/k9s-offline-install.sh
git commit -m "feat(k9s): add k9s-offline-install.sh for offline installation"
```

---

### Task 4: 创建 k9s-tag.sh

**Files:**
- Create: `k9s-setup/k9s-tag.sh`

打包脚本，参考 `docker-bin-setup-offline/tag.sh` 的打包模式。

- [ ] **Step 1: 编写 k9s-tag.sh**

```bash
#!/bin/bash
# 将 k9s 离线部署文件打包为交付 tar.gz
# 打包内容: k9s-offline-install.sh + packages/k9s + packages/README.md

set -e

# 架构参数
K9S_ARCH="${K9S_ARCH:-}"

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 解析命令行参数
while getopts "a:" opt; do
  case "${opt}" in
    a) K9S_ARCH="${OPTARG}" ;;
    *) echo "用法: $0 [-a 架构(amd64/arm64)]"; exit 1 ;;
  esac
done

# 架构检测
if [ -z "${K9S_ARCH}" ]; then
  case "$(uname -m)" in
    x86_64) K9S_ARCH="amd64" ;;
    aarch64|arm64) K9S_ARCH="arm64" ;;
    *)
      echo "不支持的架构: $(uname -m)"
      echo "请通过 -a 参数指定架构 (amd64/arm64)"
      exit 1
      ;;
  esac
fi

# 校验架构
case "${K9S_ARCH}" in
  amd64|arm64) ;;
  *)
    echo "不支持的架构: ${K9S_ARCH}，仅支持 amd64 或 arm64"
    exit 1
    ;;
esac

# 校验必要文件存在
if [ ! -f "${SCRIPT_DIR}/packages/k9s" ]; then
  echo "找不到 k9s 二进制: ${SCRIPT_DIR}/packages/k9s"
  echo "请先运行 k9s-download.sh 下载二进制"
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/k9s-offline-install.sh" ]; then
  echo "找不到安装脚本: ${SCRIPT_DIR}/k9s-offline-install.sh"
  exit 1
fi

OUTPUT_FILE="k9s-offline-${K9S_ARCH}.tar.gz"

echo ">>> 打包离线交付物: ${OUTPUT_FILE}"

# 进入脚本目录打包（保证 tar 包内路径正确）
cd "${SCRIPT_DIR}"
tar -czvf "${OUTPUT_FILE}" \
  k9s-offline-install.sh \
  packages/k9s \
  packages/README.md

echo ">>> 离线交付物已打包: ${SCRIPT_DIR}/${OUTPUT_FILE}"
echo ">>> 文件大小: $(du -h "${OUTPUT_FILE}" | cut -f1)"
echo ""
echo "下一步: 拷贝到离线机器并安装"
echo "  scp ${OUTPUT_FILE} offline-server:/tmp/"
echo "  cd /tmp && tar xzf ${OUTPUT_FILE}"
echo "  sudo ./k9s-offline-install.sh"
```

写入文件 `k9s-setup/k9s-tag.sh`。

- [ ] **Step 2: 设置执行权限并提交**

```bash
chmod +x k9s-setup/k9s-tag.sh
git add k9s-setup/k9s-tag.sh
git commit -m "feat(k9s): add k9s-tag.sh for offline package bundling"
```

---

### Task 5: 更新 README.md

**Files:**
- Modify: `k9s-setup/README.md`

在现有 README.md 中补充离线部署章节。

- [ ] **Step 1: 更新 README.md**

在现有 `## Deploy` 章节之后追加离线部署章节：

```markdown
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
INSTALL_DIR=$HOME/bin sudo ./k9s-offline-install.sh
```
```

- [ ] **Step 2: 提交**

```bash
git add k9s-setup/README.md
git commit -m "doc(k9s): update README with offline deploy instructions"
```

---

## Self-Review

### 1. Spec coverage check

| Spec 要求 | 对应 Task |
|-----------|-----------|
| k9s-download.sh 脚本 | Task 2 |
| k9s-offline-install.sh 脜本 | Task 3 |
| k9s-tag.sh 脜本 | Task 4 |
| packages/ 目录 + README.md | Task 1 |
| .gitignore 排除 packages/k9s | Task 1 |
| README.md 更新离线部署说明 | Task 5 |
| 版本解析（latest 从 GitHub API） | Task 2 |
| 架构检测 + -a 参数覆盖 | Task 2, 3, 4 |
| 交互式进度条/非交互静默 | Task 2 |
| set -e 错误处理 | Task 2, 3, 4 |
| INSTALL_DIR 环境变量 | Task 3 |
| -p 参数指定 tar 包路径 | Task 3 |
| 双架构支持 (amd64/arm64) | Task 2, 4 |

### 2. Placeholder scan

无 TBD/TODO/implement later/适当处理 等占位符。所有步骤包含完整代码。

### 3. Type consistency

- 架构参数统一使用 `K9S_ARCH`，值统一为 `amd64`/`arm64`
- `SCRIPT_DIR` 在三个脚本中使用相同获取方式
- `INSTALL_DIR` 默认值统一为 `/usr/local/bin`
- `PACKAGES_DIR` 在 download 中为 `${SCRIPT_DIR}/packages`，在 offline-install 中为 `${SCRIPT_DIR}/packages/k9s` — 一致