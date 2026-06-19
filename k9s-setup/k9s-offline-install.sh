#!/bin/bash
# 在离线环境安装 k9s 二进制
# K9s 官方仓库: https://github.com/derailed/k9s

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while getopts "p:" opt; do
  case "${opt}" in
    p) TARBALL_PATH="${OPTARG}" ;;
    *) echo "用法: $0 [-p 离线包路径(k9s-offline-<arch>.tar.gz)]" >&2; exit 1 ;;
  esac
done

K9S_BIN="${SCRIPT_DIR}/packages/k9s"

if [ -n "${TARBALL_PATH:-}" ]; then
  echo ">>> 解压离线包: ${TARBALL_PATH}"
  # 解压到临时目录再选择性拷贝，避免恶意/损坏的 tar 通过路径前缀覆盖脚本本身
  EXTRACT_DIR="$(mktemp -d)"
  trap 'rm -rf "${EXTRACT_DIR}"' EXIT
  tar -xzf "${TARBALL_PATH}" -C "${EXTRACT_DIR}"
  mkdir -p "${SCRIPT_DIR}/packages"
  [ -f "${EXTRACT_DIR}/packages/k9s" ] && cp "${EXTRACT_DIR}/packages/k9s" "${K9S_BIN}"
  [ -f "${EXTRACT_DIR}/k9s-offline-install.sh" ] && cp "${EXTRACT_DIR}/k9s-offline-install.sh" "${SCRIPT_DIR}/"
fi

if [ ! -f "${K9S_BIN}" ]; then
  echo "找不到 k9s 二进制文件: ${K9S_BIN}" >&2
  echo "请确保已解压离线包或 packages/k9s 文件存在" >&2
  exit 1
fi

echo ">>> 准备安装 k9s 到 ${INSTALL_DIR}"
install -m 0755 "${K9S_BIN}" "${INSTALL_DIR}/k9s"
echo ">>> k9s 已安装到 ${INSTALL_DIR}/k9s"

if command -v k9s >/dev/null 2>&1; then
  timeout 10 k9s version --short 2>/dev/null \
    || timeout 10 "${INSTALL_DIR}/k9s" version --short 2>/dev/null \
    || echo ">>> (跳过版本校验)"
else
  echo ">>> 安装校验: 请确认 ${INSTALL_DIR} 在 PATH 中"
fi
