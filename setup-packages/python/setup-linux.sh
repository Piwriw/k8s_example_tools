#!/bin/bash

# 在任何命令失败时退出脚本，并显示失败的命令行号
set -euo pipefail
trap 'echo "Error occurred at line $LINENO: $BASH_COMMAND"' ERR

# 临时目录设置
TEMP_DIR=$(mktemp -d)
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# 检查并获取Python版本
get_python_version() {
    if [[ $# -ne 1 ]] || [[ $1 != --version=* ]]; then
        read -p "Please enter the Python version you want to install (e.g., 3.9.0): " PYTHON_VERSION
        if [[ -z "$PYTHON_VERSION" ]]; then
            error "Python version cannot be empty."
        fi
    else
        PYTHON_VERSION="${1#--version=}"
    fi
    log "Python version set to $PYTHON_VERSION"
}

# 下载Python安装包
download_python() {
    local url="https://mirrors.aliyun.com/python-release/source/Python-${PYTHON_VERSION}.tgz"
    log "Downloading Python $PYTHON_VERSION from $url..."
    if ! wget -P "$TEMP_DIR" "$url"; then
        error "Failed to download Python $PYTHON_VERSION. Please check the version number or your network connection."
    fi
}

# 解压Python安装包
extract_python() {
    log "Extracting Python $PYTHON_VERSION..."
    if ! tar -zxvf "$TEMP_DIR/Python-${PYTHON_VERSION}.tgz" -C "$TEMP_DIR"; then
        error "Failed to extract Python $PYTHON_VERSION. Please check the downloaded file."
    fi
}

# 安装依赖项
install_dependencies() {
    log "Installing dependencies..."
    if ! yum install -y gcc make cmake zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel; then
        error "Failed to install dependencies. Please check your package manager and network connection."
    fi
}

# 编译并安装Python
build_and_install_python() {
    log "Configuring and installing Python $PYTHON_VERSION..."
    cd "$TEMP_DIR/Python-${PYTHON_VERSION}"
    if ! sudo ./configure --prefix=/usr/local/python3 --with-ssl; then
        error "Failed to configure Python $PYTHON_VERSION. Please check the configuration options."
    fi

    if ! make && make install; then
        error "Failed to compile and install Python $PYTHON_VERSION."
    fi
}

# 更新环境变量并检查Python安装
update_path_and_check() {
    log "Checking installation..."
    if ! command -v python3 &>/dev/null; then
        log "Python3 command not found. Updating PATH..."
        echo "export PATH=\$PATH:/usr/local/python3/bin" >> ~/.bashrc
        source ~/.bashrc
    fi

    # 检查Python版本是否与用户输入的一致
    installed_version=$(python3 -V 2>&1 | awk '{print $2}')
    if [[ "$installed_version" != "$PYTHON_VERSION" ]]; then
        error "Installed Python version ($installed_version) does not match the requested version ($PYTHON_VERSION)."
        log "Maybe You should Remove Your Old Python3 Before"
    fi

    if ! pip3 -V; then
        error "pip installation failed. Please check the installation process."
    fi
}

# 配置pip使用阿里云镜像源（当pip3版本大于10.0.0时）
configure_pip_mirror() {
    log "Checking pip version..."
    pip_version=$(pip3 --version | awk '{print $2}')
    pip_version_major_minor=$(echo "$pip_version" | awk -F. '{print $1"."$2}')

    if [[ "$(echo "$pip_version_major_minor > 10.0" | bc)" -eq 1 ]]; then
        log "Configuring pip to use Aliyun mirror..."
        if ! pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/; then
            error "Failed to configure pip mirror. Please check your pip configuration."
        fi
    else
        log "pip version ($pip_version) is not greater than 10.0. Skipping mirror configuration."
    fi
}

# 主流程
main() {
    get_python_version "$@"
    download_python
    extract_python
    install_dependencies
    build_and_install_python
    update_path_and_check
    configure_pip_mirror

    log "Python $PYTHON_VERSION installation completed successfully and Aliyun mirror configured."
}

main "$@"
