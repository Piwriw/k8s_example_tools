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
