#!/usr/bin/env bash
#
# Python 安装脚本（Linux，支持 RHEL/CentOS 与 Ubuntu/Debian 系）
# 用法:  bash setup-linux.sh <version>
# 示例:  bash setup-linux.sh 3.9.0
#
set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Error occurred at line $LINENO: $BASH_COMMAND" >&2' ERR

# ---------- 常量 ----------
readonly SCRIPT_NAME=$(basename "$0")
readonly TEMP_DIR=$(mktemp -d)
readonly PYTHON_PREFIX="/usr/local/python3"
readonly PYTHON_PROFILE_FILE="/etc/profile.d/python3.sh"

# ---------- 日志 ----------
log()      { echo "[INFO]  $*"; }
log_warn() { echo "[WARN]  $*" >&2; }
error()    { echo "[ERROR] $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage:  bash $SCRIPT_NAME <version>

Example:
    bash $SCRIPT_NAME 3.9.0
EOF
    exit 1
}

# ---------- 清理 ----------
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# ---------- 工具函数 ----------
ensure_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        error "未找到 sudo，请以 root 身份执行或安装 sudo。"
    fi
}

detect_os() {
    if   command -v apt-get  >/dev/null 2>&1; then echo "debian"
    elif command -v dnf      >/dev/null 2>&1; then echo "fedora"
    elif command -v yum      >/dev/null 2>&1; then echo "rhel"
    else error "未识别的包管理器（需要 apt/dnf/yum 之一）。"; fi
}

get_python_version() {
    if [[ $# -ne 1 ]] || [[ $1 != --version=* ]]; then
        read -rp "请输入要安装的 Python 版本（例如 3.9.0）: " PYTHON_VERSION
        if [[ -z "$PYTHON_VERSION" ]]; then
            error "Python 版本不能为空。"
        fi
    else
        PYTHON_VERSION="${1#--version=}"
    fi

    # 仅允许数字与点的版本号
    if [[ ! "$PYTHON_VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
        error "版本号格式不合法: '$PYTHON_VERSION'，期望形如 3.9.0"
    fi
    log "Python 版本设置为 $PYTHON_VERSION"
}

# ---------- 下载与解压 ----------
download_python() {
    local url="https://mirrors.aliyun.com/python-release/source/Python-${PYTHON_VERSION}.tgz"
    log "正在从 $url 下载 Python $PYTHON_VERSION ..."
    if ! wget -q --show-progress -P "$TEMP_DIR" "$url"; then
        error "下载 Python $PYTHON_VERSION 失败，请检查版本号或网络。"
    fi
}

extract_python() {
    log "正在解压 Python $PYTHON_VERSION ..."
    if ! tar -xzf "$TEMP_DIR/Python-${PYTHON_VERSION}.tgz" -C "$TEMP_DIR"; then
        error "解压 Python $PYTHON_VERSION 失败，请检查下载文件。"
    fi
}

# ---------- 依赖安装 ----------
install_dependencies() {
    local os="$1"
    log "正在通过 $os 安装编译依赖 ..."
    case "$os" in
        debian)
            sudo apt-get update
            sudo apt-get install -y \
                build-essential cmake \
                zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
                libssl-dev libxz-dev libffi-dev
            ;;
        fedora)
            sudo dnf install -y \
                gcc make cmake \
                zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
                openssl-devel xz xz-devel libffi-devel
            ;;
        rhel)
            sudo yum install -y \
                gcc make cmake \
                zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
                openssl-devel xz xz-devel libffi-devel
            ;;
        *)
            error "未支持的包管理器: $os"
            ;;
    esac
}

# ---------- 编译安装 ----------
build_and_install_python() {
    log "正在配置与编译 Python $PYTHON_VERSION ..."
    pushd "$TEMP_DIR/Python-${PYTHON_VERSION}" >/dev/null

    if ! sudo ./configure --prefix="$PYTHON_PREFIX" --with-ssl; then
        popd >/dev/null
        error "配置 Python $PYTHON_VERSION 失败，请检查 configure 选项。"
    fi

    if ! make -j"$(nproc 2>/dev/null || echo 2)"; then
        popd >/dev/null
        error "编译 Python $PYTHON_VERSION 失败。"
    fi

    if ! sudo make install; then
        popd >/dev/null
        error "安装 Python $PYTHON_VERSION 失败。"
    fi

    popd >/dev/null
}

# ---------- 环境变量与检查 ----------
update_path_and_check() {
    log "正在写入环境变量到 $PYTHON_PROFILE_FILE ..."
    sudo tee "$PYTHON_PROFILE_FILE" >/dev/null <<EOF
# Python environment
export PATH=\$PATH:$PYTHON_PREFIX/bin
EOF
    sudo chmod 0644 "$PYTHON_PROFILE_FILE"

    log "正在检查安装结果 ..."
    if ! command -v "$PYTHON_PREFIX/bin/python3" >/dev/null 2>&1; then
        error "未找到 $PYTHON_PREFIX/bin/python3，请检查安装过程。"
    fi

    local installed_version
    installed_version=$("$PYTHON_PREFIX/bin/python3" -V 2>&1 | awk '{print $2}')
    if [[ "$installed_version" != "$PYTHON_VERSION" ]]; then
        error "已安装的 Python 版本 ($installed_version) 与请求的版本 ($PYTHON_VERSION) 不一致。
提示: 如果系统中存在其他 python3，请先移除再重试。"
    fi

    if ! "$PYTHON_PREFIX/bin/pip3" -V >/dev/null 2>&1; then
        error "pip 不可用，请检查安装过程。"
    fi
}

configure_pip_mirror() {
    log "正在配置 pip 镜像源 ..."
    local pip_version
    pip_version=$("$PYTHON_PREFIX/bin/pip3" --version | awk '{print $2}')
    local pip_version_major_minor
    pip_version_major_minor=$(echo "$pip_version" | awk -F. '{print $1"."$2}')

    # 使用 sort -V 做版本比较，替代 bc（bc 在精简镜像中可能缺失）
    if [[ "$(printf '%s\n' "10.0" "$pip_version_major_minor" | sort -V | tail -n1)" == "$pip_version_major_minor" \
          && "$pip_version_major_minor" != "10.0" ]]; then
        if ! "$PYTHON_PREFIX/bin/pip3" config set global.index-url https://mirrors.aliyun.com/pypi/simple/; then
            error "配置 pip 镜像源失败，请检查 pip 配置。"
        fi
    else
        log "pip 版本 ($pip_version) <= 10.0，跳过镜像源配置。"
    fi
}

# ---------- 主流程 ----------
main() {
    ensure_sudo
    get_python_version "$@"

    local os
    os=$(detect_os)
    log "检测到包管理器: $os"

    download_python
    extract_python
    install_dependencies "$os"
    build_and_install_python
    update_path_and_check
    configure_pip_mirror

    log "Python $PYTHON_VERSION 安装完成，并已配置阿里云 pip 镜像源。"
    log "请执行 'source $PYTHON_PROFILE_FILE' 或重新登录以使环境变量生效。"
}

main "$@"
