#!/bin/bash
set -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行images-export"
    echo "export OUTPUTDIR=exported_images"
    echo "export NAMESPACE=default"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "OUTPUTDIR="${OUTPUTDIR}
    echo "NAMESPACE="${NAMESPACE}
    echo ""
}

doImageExport() {
mkdir -p "${OUTPUTDIR}"
  kubectl get pods -n ${NAMESPACE} -o jsonpath="{.items[*].spec.containers[*].image}"| tr -s '[[:space:]]' '\n' | sort | uniq | while read -r image; do
    tm=$(echo "$image" | rev | cut -d '/' -f 1)
    name=$(echo "$tm" |rev |cut -d ':' -f 1)
    tag=$(echo "$tm" |rev| cut -d ':' -f 2)
    output_file="$OUTPUTDIR/${name}_${tag}.tar"
    docker save -o "$output_file" "$image"
    echo "$output_file has Exported"
  done
}

if [ ${#OUTPUTDIR} -eq 0 ] || [ ${#NAMESPACE} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doImageExport