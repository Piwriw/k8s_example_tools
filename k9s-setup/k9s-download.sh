#!/bin/bash
# 在有网环境下载 k9s 二进制文件，用于离线部署
# K9s 官方仓库: https://github.com/derailed/k9s

set -euo pipefail

K9S_VERSION="${K9S_VERSION:-latest}"
K9S_ARCH="${K9S_ARCH:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while getopts "v:a:" opt; do
  case "${opt}" in
    v) K9S_VERSION="${OPTARG}" ;;
    a) K9S_ARCH="${OPTARG}" ;;
    *) echo "用法: $0 [-v 版本号] [-a 架构(amd64/arm64)]" >&2; exit 1 ;;
  esac
done

# 未指定 -a 时取当前机器架构；同时统一别名并校验合法性
if [ -z "${K9S_ARCH}" ]; then
  K9S_ARCH="$(uname -m)"
fi
case "${K9S_ARCH}" in
  x86_64|amd64) K9S_ARCH="amd64" ;;
  aarch64|arm64) K9S_ARCH="arm64" ;;
  *)
    echo "不支持的架构: ${K9S_ARCH}（仅 amd64/arm64）" >&2
    echo "请通过 -a 参数指定目标架构" >&2
    exit 1
    ;;
esac

# 离线目标固定为 Linux 服务器，不取本机 OS（打包机器可能是 macOS）
TARGET_OS="Linux"
TARBALL="k9s_${TARGET_OS}_${K9S_ARCH}.tar.gz"

if [ "${K9S_VERSION}" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/derailed/k9s/releases/latest/download/${TARBALL}"
  K9S_VERSION="$(curl -fsSI -o /dev/null -w '%{redirect_url}' "${DOWNLOAD_URL}" \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+[^/]*' | tail -1 || true)"
  [ -n "${K9S_VERSION}" ] || { echo "无法解析 K9s 版本号" >&2; exit 1; }
else
  DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${TARBALL}"
fi

echo ">>> 准备下载 K9s ${K9S_VERSION} (${TARGET_OS}/${K9S_ARCH})"
echo ">>> 下载地址: ${DOWNLOAD_URL}"

PACKAGES_DIR="${SCRIPT_DIR}/packages"
mkdir -p "${PACKAGES_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [ -t 2 ]; then
  curl -fL --progress-bar "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
else
  curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
fi

# 直接解压到目标目录，省一次 cp
tar -xzf "${TMP_DIR}/${TARBALL}" -C "${PACKAGES_DIR}" k9s
chmod +x "${PACKAGES_DIR}/k9s"

echo ">>> K9s ${K9S_VERSION} (${TARGET_OS}/${K9S_ARCH}) 已下载到 ${PACKAGES_DIR}/k9s"
echo ">>> 文件大小: $(du -h "${PACKAGES_DIR}/k9s" | cut -f1)"
echo ""
echo "下一步: 运行 k9s-tag.sh 打包为离线交付物"
echo "  ./k9s-tag.sh -a ${K9S_ARCH}"
