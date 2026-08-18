#!/bin/bash
#
# =============================================================================
#  纪贺 SillyTavern 脚本更新工具 (JH-Updater)
#  版本: v1.0.8
#  作者: 纪贺 (ignite661)
#  说明: 通过 GitHub Release 整包更新所有脚本文件
#
#  使用:
#  - 在管理系统中选“检查脚本更新”即可自动调用
#  - 也可以手动执行: bash ~/update.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# 配置
# -----------------------------------------------------------------------------
REPO="ignite661/JH-SillyTavern-Manager"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
RELEASE_URL="https://github.com/$REPO/releases/latest/download/jh-update.zip"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$HOME/.jh_version"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 需要更新/校验的脚本文件
SCRIPT_FILES=("install.sh" "jh_manager.sh" "update.sh")

# -----------------------------------------------------------------------------
# 颜色与提示
# -----------------------------------------------------------------------------
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_DIM='\033[2m'

info() { echo -e "${C_CYAN}$1${C_RESET}"; }
ok()   { echo -e "${C_GREEN}✅ $1${C_RESET}"; }
warn() { echo -e "${C_YELLOW}⚠️  $1${C_RESET}"; }
err()  { echo -e "${C_RED}❌ $1${C_RESET}" >&2; }
die()  { err "$1"; exit "${2:-1}"; }

# -----------------------------------------------------------------------------
# 获取本地版本
# -----------------------------------------------------------------------------
get_local_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        head -n1 "$VERSION_FILE" 2>/dev/null || echo "未知版本"
    else
        echo "未知版本"
    fi
}

# -----------------------------------------------------------------------------
# 检查 unzip
# -----------------------------------------------------------------------------
check_unzip() {
    if command -v unzip >/dev/null 2>&1; then
        return 0
    fi
    if [[ "${PREFIX:-}" == *"/com.termux"* ]]; then
        echo -e "${C_YELLOW}缺少 unzip，正在安装...${C_RESET}"
        pkg install -y unzip
    else
        die "缺少 unzip，请先安装 unzip 后再更新。"
    fi
}

# -----------------------------------------------------------------------------
# 主流程
# -----------------------------------------------------------------------------
main() {
    clear
    echo -e "${C_CYAN}"
    echo "   ╔══════════════════════════════════════════════╗"
    echo "   ║       🔄 纪贺 SillyTavern 脚本更新工具       ║"
    echo "   ║         让脚本也保持新鲜～                   ║"
    echo "   ╚══════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo

    info "正在从 GitHub 获取最新版本信息..."
    # 加时间戳参数绕过 raw 的 CDN 缓存，避免拿到旧版 VERSION
    local remote_info remote_version local_version
    remote_info="$(curl -fsSL --connect-timeout 15 -H 'Cache-Control: no-cache' "$RAW_BASE/VERSION?t=$(date +%s)" 2>/dev/null || true)"
    remote_version="$(printf '%s\n' "$remote_info" | head -n1 || true)"
    local_version="$(get_local_version)"

    echo -e "  本地版本：${C_GREEN}$local_version${C_RESET}"
    if [[ -n "$remote_version" ]]; then
        echo -e "  远程版本：${C_YELLOW}$remote_version${C_RESET}"
        echo
        echo -e "${C_CYAN}📢 更新内容：${C_RESET}"
        printf '%s\n' "$remote_info" | tail -n +2 | sed '/^\s*$/d'
        echo
    else
        warn "远程版本获取失败，请检查网络/代理后再试。"
        exit 1
    fi

    if [[ "$local_version" == "$remote_version" ]]; then
        echo -e "${C_GREEN}当前已是最新版本（$remote_version）。${C_RESET}"
        read -rp "是否仍要强制重新下载覆盖？(y/n): " force
        force="${force//[[:space:]]/}"
        if [[ ! "$force" =~ ^[yY]$ ]]; then
            echo "好，已取消。"
            exit 0
        fi
        echo "开始强制更新..."
    fi

    echo
    read -rp "是否更新脚本？(y/n): " confirm
    confirm="${confirm//[[:space:]]/}"
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "好，已取消。"
        exit 0
    fi

    check_unzip

    echo
    info "正在下载整包更新..."
    local zip_file="$TMP_DIR/jh-update.zip"
    if ! curl -fL --connect-timeout 20 --retry 3 -H 'Cache-Control: no-cache' -o "$zip_file" "$RELEASE_URL?t=$(date +%s)"; then
        die "下载更新包失败，请检查网络后重试。"
    fi

    local update_dir="$TMP_DIR/update"
    mkdir -p "$update_dir"
    if ! unzip -oq "$zip_file" -d "$update_dir"; then
        die "解压更新包失败，压缩包可能损坏。"
    fi

    # 校验更新包内容
    local f
    for f in "${SCRIPT_FILES[@]}"; do
        if [[ ! -f "$update_dir/$f" ]]; then
            die "更新包缺少 $f，已取消更新。"
        fi
        if ! bash -n "$update_dir/$f"; then
            die "更新包中的 $f 语法校验失败，已取消更新。"
        fi
    done
    if [[ ! -s "$update_dir/VERSION" ]]; then
        die "更新包缺少 VERSION，已取消更新。"
    fi

    # 备份旧文件
    local stamp
    stamp="$(date +%Y%m%d_%H%M%S)"
    for f in "${SCRIPT_FILES[@]}"; do
        [[ -f "$SCRIPT_DIR/$f" ]] && cp -f "$SCRIPT_DIR/$f" "$SCRIPT_DIR/$f.bak_$stamp"
    done
    [[ -f "$VERSION_FILE" ]] && cp -f "$VERSION_FILE" "$VERSION_FILE.bak_$stamp"

    # 覆盖为新版
    for f in "${SCRIPT_FILES[@]}"; do
        install -m 755 "$update_dir/$f" "$SCRIPT_DIR/$f"
    done
    install -m 644 "$update_dir/VERSION" "$VERSION_FILE"

    echo
    ok "脚本更新完成～"
    echo -e "${C_DIM}旧文件备份在：$SCRIPT_DIR/*.bak_$stamp${C_RESET}"
    echo -e "${C_YELLOW}提示：重启管理系统后生效（当前窗口可以先退出）。${C_RESET}"
    exit 0
}

main
