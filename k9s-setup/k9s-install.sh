#!/bin/bash
# 通过下载二进制方式安装 K9s
# K9s 官方仓库: https://github.com/derailed/k9s

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
K9S_VERSION="${K9S_VERSION:-latest}"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$(uname -m)" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "不支持的架构: $(uname -m)" >&2
    exit 1
    ;;
esac

TARBALL="k9s_${OS}_${ARCH}.tar.gz"

# latest 走 releases/latest/download 让 GitHub 自动 redirect，省一次 API 调用、避开 60 次/小时限流
if [ "${K9S_VERSION}" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/derailed/k9s/releases/latest/download/${TARBALL}"
  # redirect 目标形如 .../download/v0.32.5/k9s_linux_amd64.tar.gz，从中解析版本号用于展示
  K9S_VERSION="$(curl -fsSI -o /dev/null -w '%{redirect_url}' "${DOWNLOAD_URL}" \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+[^/]*' | tail -1 || true)"
  [ -n "${K9S_VERSION}" ] || { echo "无法解析 K9s 版本号" >&2; exit 1; }
else
  DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${TARBALL}"
fi

echo ">>> 准备安装 K9s ${K9S_VERSION} (${OS}/${ARCH})"
echo ">>> 下载地址: ${DOWNLOAD_URL}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# -t 2 检测 stderr 是否为 tty：交互式终端显示进度条，CI/管道静默下载
if [ -t 2 ]; then
  curl -fL --progress-bar "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
else
  curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL}"
fi

tar -xzf "${TMP_DIR}/${TARBALL}" -C "${TMP_DIR}" k9s
install -m 0755 "${TMP_DIR}/k9s" "${INSTALL_DIR}/k9s"

echo ">>> K9s ${K9S_VERSION} 已安装到 ${INSTALL_DIR}/k9s"
# timeout 防 TUI 模式意外挂起卡住 CI
timeout 10 k9s version --short 2>/dev/null \
  || timeout 10 "${INSTALL_DIR}/k9s" version --short 2>/dev/null \
  || echo ">>> (跳过版本校验)"
