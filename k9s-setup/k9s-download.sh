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
