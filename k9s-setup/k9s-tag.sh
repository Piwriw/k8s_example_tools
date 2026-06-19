#!/bin/bash
# 将 k9s 离线部署文件打包为交付 tar.gz
# 打包内容: k9s-offline-install.sh + packages/k9s + packages/README.md

set -euo pipefail

K9S_ARCH="${K9S_ARCH:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while getopts "a:" opt; do
  case "${opt}" in
    a) K9S_ARCH="${OPTARG}" ;;
    *) echo "用法: $0 [-a 架构(amd64/arm64)]" >&2; exit 1 ;;
  esac
done

if [ -z "${K9S_ARCH}" ]; then
  K9S_ARCH="$(uname -m)"
fi
case "${K9S_ARCH}" in
  x86_64|amd64) K9S_ARCH="amd64" ;;
  aarch64|arm64) K9S_ARCH="arm64" ;;
  *)
    echo "不支持的架构: ${K9S_ARCH}（仅 amd64/arm64）" >&2
    echo "请通过 -a 参数指定架构" >&2
    exit 1
    ;;
esac

if [ ! -f "${SCRIPT_DIR}/packages/k9s" ]; then
  echo "找不到 k9s 二进制: ${SCRIPT_DIR}/packages/k9s" >&2
  echo "请先运行 k9s-download.sh 下载二进制" >&2
  exit 1
fi

OUTPUT_FILE="k9s-offline-${K9S_ARCH}.tar.gz"

echo ">>> 打包离线交付物: ${OUTPUT_FILE}"

cd "${SCRIPT_DIR}"
# --exclude 防止把旧的离线包意外打进新包
tar -czvf "${OUTPUT_FILE}" \
  --exclude='k9s-offline-*.tar.gz' \
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
