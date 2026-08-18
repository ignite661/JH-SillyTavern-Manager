#!/bin/bash
#
# =============================================================================
#  纪贺 SillyTavern 一键安装脚本 (JH-Installer)
#  版本: v1.0.0
#  作者: 纪贺 (ignite661)
#  说明: 在 Termux 原生环境一键部署 SillyTavern（酒馆）
#
#  更新:
#  - 轻量化重构，原生 Termux 直跑
#  - 手动检查更新，启动零网络请求
#  - 新增备份/恢复能力（由管理系统提供）
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# 版本与配置
# -----------------------------------------------------------------------------
JH_VERSION="v1.0.0"
MANAGER_FILENAME="jh_manager.sh"
UPDATE_FILENAME="update.sh"
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"
ST_BRANCH="release"
MIN_NODE_VERSION="v23.11.0"

# 远程文件地址
RAW_BASE="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main"
JH_MANAGER_URL="$RAW_BASE/jh_manager.sh"
JH_UPDATE_URL="$RAW_BASE/update.sh"
JH_VERSION_URL="$RAW_BASE/VERSION"

# -----------------------------------------------------------------------------
# 颜色与提示
# -----------------------------------------------------------------------------
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_DIM='\033[2m'

info()  { echo -e "${C_CYAN}$1${C_RESET}"; }
ok()    { echo -e "${C_GREEN}✅ $1${C_RESET}"; }
warn()  { echo -e "${C_YELLOW}⚠️  $1${C_RESET}"; }
err()   { echo -e "${C_RED}❌ $1${C_RESET}" >&2; }
die()   { err "$1"; exit "${2:-1}"; }

# -----------------------------------------------------------------------------
# 欢迎界面
# -----------------------------------------------------------------------------
show_banner() {
    clear
    echo -e "${C_CYAN}"
    echo "   ╔══════════════════════════════════════════════╗"
    echo "   ║      🍷 纪贺 SillyTavern 一键安装脚本       ║"
    echo "   ║          你的酒馆，马上开张～                ║"
    echo "   ╚══════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo -e "${C_DIM}   JH-Installer ${JH_VERSION}${C_RESET}"
    echo
}

# -----------------------------------------------------------------------------
# 检查是否在 Termux
# -----------------------------------------------------------------------------
check_termux() {
    if [[ "${PREFIX:-}" != *"/com.termux"* ]]; then
        die "看起来这不是 Termux 环境。本脚本只在 Termux 中运行哦～"
    fi
}

# -----------------------------------------------------------------------------
# 安装系统依赖
# -----------------------------------------------------------------------------
install_deps() {
    info "📦 正在更新软件源并安装依赖，请稍等..."
    echo
    pkg update -y
    pkg install -y git nodejs curl jq
    echo
    ok "基础依赖安装完成～"
}

# -----------------------------------------------------------------------------
# 检查 Node.js 版本（Wiki 教程要求不低于 v23.11.0）
# -----------------------------------------------------------------------------
check_node_version() {
    local node_version
    node_version="$(node -v 2>/dev/null || true)"
    if [[ -z "$node_version" ]]; then
        die "没有检测到 Node.js，安装可能出了问题，请重试。"
    fi

    local lowest
    lowest="$(printf '%s\n' "$node_version" "$MIN_NODE_VERSION" | sort -V | head -n1)"
    if [[ "$lowest" != "$MIN_NODE_VERSION" ]]; then
        warn "当前 Node.js 版本: $node_version"
        die "需要 Node.js >= $MIN_NODE_VERSION，请先升级 Termux / 更换软件源后再试。"
    fi

    ok "Node.js 版本符合要求：$node_version"
}

# -----------------------------------------------------------------------------
# 克隆 / 更新 SillyTavern
# -----------------------------------------------------------------------------
install_sillytavern() {
    if [[ -d "$HOME/$ST_DIR_NAME/.git" ]]; then
        warn "检测到已有酒馆目录，正在帮你拉取最新代码..."
        if ! (cd "$HOME/$ST_DIR_NAME" && git pull --ff-only); then
            die "酒馆代码更新失败，请检查网络后重试。"
        fi
    elif [[ -d "$HOME/$ST_DIR_NAME" ]]; then
        die "发现 $HOME/$ST_DIR_NAME 已存在，但它不是酒馆仓库。请先备份重要数据并删除该目录后再安装。"
    else
        info "正在从 GitHub 克隆 SillyTavern（${ST_BRANCH} 分支）..."
        if ! git clone --depth 1 --branch "$ST_BRANCH" "$ST_REPO_URL" "$HOME/$ST_DIR_NAME"; then
            die "克隆 SillyTavern 失败，请检查网络/代理后重试。"
        fi
    fi
    ok "酒馆主程序准备完毕～"
}

# -----------------------------------------------------------------------------
# 安装 pnpm
# -----------------------------------------------------------------------------
install_pnpm() {
    if command -v pnpm &>/dev/null; then
        ok "pnpm 已存在：$(pnpm -v 2>/dev/null || echo '未知版本')"
    else
        info "正在安装 pnpm 包管理器..."
        if ! npm install -g pnpm < /dev/null; then
            die "pnpm 安装失败，请检查网络后重试。"
        fi
        ok "pnpm 安装完成：$(pnpm -v 2>/dev/null || echo '未知版本')"
    fi
}

# -----------------------------------------------------------------------------
# 安装酒馆依赖
# -----------------------------------------------------------------------------
install_st_deps() {
    info "正在安装酒馆依赖，这可能需要几分钟，请耐心等待..."
    if ! (cd "$HOME/$ST_DIR_NAME" && pnpm install < /dev/null); then
        die "酒馆依赖安装失败，请检查网络后重试。"
    fi
    ok "酒馆依赖全部安装完毕～"
}

# -----------------------------------------------------------------------------
# 下载管理器与更新工具
# -----------------------------------------------------------------------------
download_scripts() {
    info "正在下载管理器和更新工具..."
    curl -fsSL -o "$HOME/$MANAGER_FILENAME.tmp" "$JH_MANAGER_URL"
    curl -fsSL -o "$HOME/$UPDATE_FILENAME.tmp" "$JH_UPDATE_URL"
    curl -fsSL -o "$HOME/.jh_version" "$JH_VERSION_URL"

    mv -f "$HOME/$MANAGER_FILENAME.tmp" "$HOME/$MANAGER_FILENAME"
    mv -f "$HOME/$UPDATE_FILENAME.tmp" "$HOME/$UPDATE_FILENAME"
    chmod +x "$HOME/$MANAGER_FILENAME" "$HOME/$UPDATE_FILENAME"

    ok "管理器与更新工具下载完成～"
}

# -----------------------------------------------------------------------------
# 设置沉浸式自启动（不清空用户原有 .bashrc）
# -----------------------------------------------------------------------------
setup_autostart() {
    local mark_start="# === JH-SillyTavern 自动启动开始 ==="
    local mark_end="# === JH-SillyTavern 自动启动结束 ==="

    if grep -qF "$mark_start" "$HOME/.bashrc" 2>/dev/null; then
        warn "检测到自动启动已配置，跳过设置。"
        return
    fi

    cat >> "$HOME/.bashrc" <<EOF

$mark_start
if [ -f "\$HOME/$MANAGER_FILENAME" ]; then
    bash "\$HOME/$MANAGER_FILENAME"
fi
$mark_end
EOF

    ok "已开启沉浸式启动，下次打开 Termux 会自动进入管理系统～"
}

# -----------------------------------------------------------------------------
# 安装完成，进入管理系统
# -----------------------------------------------------------------------------
finish() {
    clear
    echo -e "${C_GREEN}"
    echo "   ╔══════════════════════════════════════════════╗"
    echo "   ║    🎉 恭喜！酒馆已经部署完成！ 🎉           ║"
    echo "   ║     接下来就交给你啦，玩得开心～             ║"
    echo "   ╚══════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo
    info "正在进入【纪贺 SillyTavern 管理系统】..."
    sleep 2

    if [[ -t 0 ]]; then
        bash "$HOME/$MANAGER_FILENAME"
    else
        # 通过 curl | bash 安装时，stdin 是管道，这里强制接回当前终端
        bash "$HOME/$MANAGER_FILENAME" < /dev/tty
    fi
}

# -----------------------------------------------------------------------------
# 主流程
# -----------------------------------------------------------------------------
main() {
    show_banner
    check_termux
    install_deps
    check_node_version
    install_sillytavern
    install_pnpm
    install_st_deps
    download_scripts
    setup_autostart
    finish
}

main
