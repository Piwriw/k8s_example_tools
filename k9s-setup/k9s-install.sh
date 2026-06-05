#!/bin/bash
# 通过下载二进制方式安装 K9s
# K9s 官方仓库: https://github.com/derailed/k9s

set -e

# 安装路径,默认为 /usr/local/bin,可通过环境变量 INSTALL_DIR 覆盖
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# K9s 版本,默认安装最新稳定版,可通过环境变量 K9S_VERSION 指定具体版本(如 v0.32.5)
K9S_VERSION="${K9S_VERSION:-latest}"

# 检测操作系统与架构
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${ARCH}" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "不支持的架构: ${ARCH}"
    exit 1
    ;;
esac

# 解析版本号(latest 则从 GitHub API 获取最新 release tag)
if [ "${K9S_VERSION}" = "latest" ]; then
  K9S_VERSION="$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest \
    | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
fi

if [ -z "${K9S_VERSION}" ]; then
  echo "无法解析 K9s 版本号"
  exit 1
fi

VERSION_NO_V="${K9S_VERSION#v}"
TARBALL="k9s_${OS}_${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${TARBALL}"

echo ">>> 准备安装 K9s ${K9S_VERSION} (${OS}/${ARCH})"
echo ">>> 下载地址: ${DOWNLOAD_URL}"

# 创建临时目录并下载
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# 交互式终端下显示进度条(--progress-bar),非交互式环境(管道/重定向)静默下载
if [ -t 2 ]; then
  curl -fL --progress-bar "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
else
  curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
fi

# 解压并安装
tar -xzf "${TMP_DIR}/${TARBALL}" -C "${TMP_DIR}" k9s
install -m 0755 "${TMP_DIR}/k9s" "${INSTALL_DIR}/k9s"

echo ">>> K9s ${K9S_VERSION} 已安装到 ${INSTALL_DIR}/k9s"
k9s version --short 2>/dev/null || "${INSTALL_DIR}/k9s" version
