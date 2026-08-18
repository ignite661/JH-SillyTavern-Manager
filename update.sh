#!/bin/bash
#
# =============================================================================
#  纪贺 SillyTavern 脚本更新工具 (JH-Updater)
#  版本: v1.0.7
#  作者: 纪贺 (ignite661)
#  说明: 从 GitHub 拉取最新版 install.sh / jh_manager.sh / update.sh
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
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 需要更新的脚本文件（相对 SCRIPT_DIR）
SCRIPT_FILES=("install.sh" "jh_manager.sh" "update.sh")
# 版本缓存文件（放在 HOME 下，避免污染脚本目录）
VERSION_FILE="$HOME/.jh_version"

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
    local remote_info remote_version
    remote_info="$(curl -fsSL --connect-timeout 15 -H 'Cache-Control: no-cache' "$RAW_BASE/VERSION?t=$(date +%s)" 2>/dev/null || true)"
    remote_version="$(printf '%s\n' "$remote_info" | head -n1 || true)"
    local local_version
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

    echo
    info "正在下载最新脚本..."

    local f attempt
    for f in "${SCRIPT_FILES[@]}"; do
        for attempt in 1 2 3; do
            # 同样加时间戳绕过 raw CDN 缓存
            if curl -fsSL --connect-timeout 20 --retry 2 -H 'Cache-Control: no-cache' -o "$SCRIPT_DIR/$f.tmp" "$RAW_BASE/$f?t=$(date +%s)"; then
                break
            fi
            warn "下载 $f 失败（第 ${attempt} 次），自动重试..."
            sleep 2
            if [[ "$attempt" -eq 3 ]]; then
                rm -f "$SCRIPT_DIR/install.sh.tmp" "$SCRIPT_DIR/jh_manager.sh.tmp" "$SCRIPT_DIR/update.sh.tmp" "$VERSION_FILE.tmp"
                die "下载 $f 失败，已保留原文件。"
            fi
        done
        # 下载后先做语法校验，避免坏文件覆盖好文件
        if ! bash -n "$SCRIPT_DIR/$f.tmp"; then
            rm -f "$SCRIPT_DIR/install.sh.tmp" "$SCRIPT_DIR/jh_manager.sh.tmp" "$SCRIPT_DIR/update.sh.tmp" "$VERSION_FILE.tmp"
            die "下载的 $f 不完整，已保留原文件。"
        fi
    done

    for attempt in 1 2 3; do
        if curl -fsSL --connect-timeout 20 --retry 2 -H 'Cache-Control: no-cache' -o "$VERSION_FILE.tmp" "$RAW_BASE/VERSION?t=$(date +%s)"; then
            break
        fi
        warn "下载 VERSION 失败（第 ${attempt} 次），自动重试..."
        sleep 2
        if [[ "$attempt" -eq 3 ]]; then
            rm -f "$SCRIPT_DIR/install.sh.tmp" "$SCRIPT_DIR/jh_manager.sh.tmp" "$SCRIPT_DIR/update.sh.tmp" "$VERSION_FILE.tmp"
            die "下载 VERSION 失败，已保留原文件。"
        fi
    done
    if [[ ! -s "$VERSION_FILE.tmp" ]]; then
        rm -f "$SCRIPT_DIR/install.sh.tmp" "$SCRIPT_DIR/jh_manager.sh.tmp" "$SCRIPT_DIR/update.sh.tmp" "$VERSION_FILE.tmp"
        die "下载的 VERSION 为空，已保留原文件。"
    fi

    # 备份旧文件
    local stamp
    stamp="$(date +%Y%m%d_%H%M%S)"
    for f in "${SCRIPT_FILES[@]}"; do
        [[ -f "$SCRIPT_DIR/$f" ]] && cp -f "$SCRIPT_DIR/$f" "$SCRIPT_DIR/$f.bak_$stamp"
    done
    [[ -f "$VERSION_FILE" ]] && cp -f "$VERSION_FILE" "$VERSION_FILE.bak_$stamp"

    # 给所有新文件加上执行权限（含 update.sh 自身）
    chmod +x "$SCRIPT_DIR/install.sh.tmp" "$SCRIPT_DIR/jh_manager.sh.tmp" "$SCRIPT_DIR/update.sh.tmp"

    # 先替换不会正在运行的脚本文件
    mv -f "$SCRIPT_DIR/install.sh.tmp" "$SCRIPT_DIR/install.sh"
    mv -f "$SCRIPT_DIR/jh_manager.sh.tmp" "$SCRIPT_DIR/jh_manager.sh"
    mv -f "$VERSION_FILE.tmp" "$VERSION_FILE"

    echo
    ok "脚本更新完成～"
    echo -e "${C_DIM}旧文件备份在：$SCRIPT_DIR/*.bak_$stamp${C_RESET}"
    echo -e "${C_YELLOW}提示：重启管理系统后生效（当前窗口可以先退出）。${C_RESET}"

    # 最后替换 update.sh 自身，然后立即退出，避免运行中的脚本被替换后出问题
    mv -f "$SCRIPT_DIR/update.sh.tmp" "$SCRIPT_DIR/update.sh"
    exit 0
}

main
