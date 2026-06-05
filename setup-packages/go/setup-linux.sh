#!/usr/bin/env bash
#
# Go 安装脚本（Linux）
# 用法:  bash setup-linux.sh <version>
# 示例:  bash setup-linux.sh 1.19
#
set -euo pipefail
IFS=$'\n\t'

# ---------- 常量 ----------
readonly SCRIPT_NAME=$(basename "$0")
readonly GO_INSTALL_DIR="/usr/local/go"
readonly GO_PROFILE_FILE="/etc/profile.d/go.sh"
readonly GO_PROXY="https://proxy.golang.com.cn,direct"
readonly TEMP_DIR=$(mktemp -d)
readonly VERSION="${1:-}"
readonly ARCH=$(uname -m)

# ---------- 日志 ----------
log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage:  bash $SCRIPT_NAME <version>

Example:
    bash $SCRIPT_NAME 1.19
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
ensure_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        log_error "未找到 curl，请先安装 curl 后重试。"
    fi
}

detect_arch() {
    case "$ARCH" in
        arm64|aarch64)
            echo "arm64"
            ;;
        x86_64|amd64)
            echo "amd64"
            ;;
        *)
            log_error "当前系统架构为 $ARCH，目前不支持该架构的安装模式。"
            ;;
    esac
}

verify_version() {
    if [[ -z "$VERSION" ]]; then
        usage
    fi
    # 仅允许数字与点的版本号，例如 1.19、1.21.4
    if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
        log_error "版本号格式不合法: '$VERSION'，期望形如 1.19 或 1.21.4"
    fi
}

# ---------- 主流程 ----------
install_go() {
    local go_arch
    go_arch=$(detect_arch)
    log_info "检测到架构: $go_arch"

    local filename="go${VERSION}.linux-${go_arch}.tar.gz"
    local url="https://studygolang.com/dl/golang/${filename}"
    local archive_path="${TEMP_DIR}/${filename}"

    log_info "正在下载: $url"
    if ! curl -fL --retry 3 -o "$archive_path" "$url"; then
        log_error "下载失败，请检查网络或版本号 ($VERSION)。"
    fi

    if [[ ! -s "$archive_path" ]]; then
        log_error "下载文件为空，请检查网络或版本号 ($VERSION)。"
    fi
    log_info "下载完成: $archive_path"

    log_info "正在解压到 $GO_INSTALL_DIR ..."
    # 已存在则先删除，避免 tar 报错
    if [[ -d "$GO_INSTALL_DIR" ]]; then
        log_warn "已存在 $GO_INSTALL_DIR，将被覆盖"
        sudo rm -rf "$GO_INSTALL_DIR"
    fi
    sudo mkdir -p "$(dirname "$GO_INSTALL_DIR")"
    sudo tar -C "$(dirname "$GO_INSTALL_DIR")" -xzf "$archive_path"
    log_info "Go 已安装到 $GO_INSTALL_DIR"
}

configure_env() {
    log_info "写入环境变量到 $GO_PROFILE_FILE"
    sudo tee "$GO_PROFILE_FILE" >/dev/null <<EOF
# Go environment
export GOROOT=$GO_INSTALL_DIR
export PATH=\$PATH:$GO_INSTALL_DIR/bin
export GOPROXY=$GO_PROXY
export GO111MODULE=on
EOF
    sudo chmod 0644 "$GO_PROFILE_FILE"
    log_info "请执行 'source $GO_PROFILE_FILE' 或重新登录以使环境变量生效。"
}

print_summary() {
    if command -v "$GO_INSTALL_DIR/bin/go" >/dev/null 2>&1; then
        log_info "Go 版本: $("$GO_INSTALL_DIR/bin/go" version)"
    else
        log_warn "未能在 $GO_INSTALL_DIR/bin/go 找到 go 命令，请检查安装结果。"
    fi
}

main() {
    ensure_curl
    verify_version
    install_go
    configure_env
    print_summary
    log_info "安装完成。"
}

main "$@"
