#!/bin/bash
set -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行helm-images-exported.sh"
    echo "export OUTPUTDIR=exported_images"
    echo "export HELM_DIR=helmdir"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "OUTPUTDIR="${OUTPUTDIR}
    echo "HELM_DIR="${HELM_DIR}
    echo ""
}

doImageExport(){
  mkdir -p "${OUTPUTDIR}"
  helm template "${HELM_DIR}" | grep -oE 'image: ?("[^"]+"|[^ ]+)' | awk -F 'image: ?' '{print $2}' | sed 's/"//g' | sort -u | while read -r line; do
      echo "Processing image: $line"
       tm=$(echo "$line" | rev | cut -d '/' -f 1)
       name=$(echo "$tm" |rev |cut -d ':' -f 1)
       tag=$(echo "$tm" |rev| cut -d ':' -f 2)
       output_file="$OUTPUTDIR/${name}_${tag}.tar"
       docker pull "$line"
       docker save -o "$output_file" "$line"
       echo "$output_file has Exported"


      # 或其他操作
  done
}
if [ ${#HELM_DIR} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doImageExport