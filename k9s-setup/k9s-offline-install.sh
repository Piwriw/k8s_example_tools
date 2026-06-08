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
