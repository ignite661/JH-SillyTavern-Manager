#!/bin/bash
#
# =============================================================================
#  纪贺 SillyTavern 一键安装脚本 (JH-Installer)
#  版本: v1.0.7
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
JH_VERSION="v1.0.7"
MANAGER_FILENAME="jh_manager.sh"
UPDATE_FILENAME="update.sh"
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"
ST_BRANCH="release"
# SillyTavern 官方在 Termux 推荐 nodejs-lts，最低 Node 18+；
# 这里用 v20 作为软检查底线，避免误伤 LTS 用户
MIN_NODE_VERSION="v20.0.0"

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
    info "📦 正在更新软件源与系统包，请稍等..."
    echo
    # --force-confdef + --force-confold: 遇到配置文件冲突时自动选默认/保留现有，
    # 避免 Termux 升级时卡在 openssl.cnf 这类交互提示上
    DEBIAN_FRONTEND=noninteractive pkg update -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"
    DEBIAN_FRONTEND=noninteractive pkg upgrade -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"
    DEBIAN_FRONTEND=noninteractive pkg install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" git nodejs-lts curl jq

    # 32 位 Android 上 SillyTavern 依赖 esbuild，需要额外安装，否则 pnpm install 会失败
    case "$(uname -m)" in
        armv7l|armv8l|arm)
            DEBIAN_FRONTEND=noninteractive pkg install -y \
                -o Dpkg::Options::="--force-confdef" \
                -o Dpkg::Options::="--force-confold" esbuild
            ;;
    esac

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

    # 这里做成“软检查”：低于建议版本只警告不退出，避免因为版本号问题卡住安装。
    # SillyTavern 官方其实支持 Node 18+，如果后面启动失败再升级 Termux 也不迟。
    local lowest
    lowest="$(printf '%s\n' "$node_version" "$MIN_NODE_VERSION" | sort -V | head -n1)"
    if [[ "$lowest" != "$MIN_NODE_VERSION" ]]; then
        warn "当前 Node.js 版本: $node_version（建议 >= $MIN_NODE_VERSION）"
        warn "先继续安装；如果之后酒馆启动失败，请先升级 Termux 再重试。"
    else
        ok "Node.js 版本符合要求：$node_version"
    fi
}

# -----------------------------------------------------------------------------
# 克隆 / 更新 SillyTavern
# -----------------------------------------------------------------------------
install_sillytavern() {
    if [[ -d "$HOME/$ST_DIR_NAME/.git" ]]; then
        warn "检测到已有酒馆目录，正在帮你拉取最新代码..."
        # --rebase --autostash: 即使有本地小改动也能自动暂存后更新，减少更新失败
        if ! (cd "$HOME/$ST_DIR_NAME" && git pull --rebase --autostash); then
            die "酒馆代码更新失败，请检查网络或本地冲突后重试。"
        fi
    elif [[ -d "$HOME/$ST_DIR_NAME" ]]; then
        die "发现 $HOME/$ST_DIR_NAME 已存在，但它不是酒馆仓库。请先备份重要数据并删除该目录后再安装。"
    else
        info "正在从 GitHub 克隆 SillyTavern（${ST_BRANCH} 分支）..."
        if ! git clone --depth 1 --branch "$ST_BRANCH" "$ST_REPO_URL" "$HOME/$ST_DIR_NAME"; then
            warn "克隆失败，可能是网络波动，自动重试一次..."
            rm -rf "$HOME/$ST_DIR_NAME"
            if ! git clone --depth 1 --branch "$ST_BRANCH" "$ST_REPO_URL" "$HOME/$ST_DIR_NAME"; then
                die "克隆 SillyTavern 失败，请检查网络/代理后重试。"
            fi
        fi
    fi
    ok "酒馆主程序准备完毕～"
}

# -----------------------------------------------------------------------------
# 安装 pnpm
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# 允许 pnpm 运行依赖构建脚本（解决 ERR_PNPM_IGNORED_BUILDS）
# -----------------------------------------------------------------------------
ensure_pnpm_builds_allowed() {
    # pnpm 10.9+ 的构建许可必须写在项目 pnpm-workspace.yaml 里，
    # 写在 ~/.npmrc 不生效（那是导致 ERR_PNPM_IGNORED_BUILDS 的根因）
    local ws="$HOME/$ST_DIR_NAME/pnpm-workspace.yaml"
    if [[ -f "$ws" ]]; then
        sed -i '/^dangerouslyAllowAllBuilds:/d' "$ws"
    fi
    echo "dangerouslyAllowAllBuilds: true" >> "$ws"
}

install_pnpm() {
    local manager="" ver="" current=""

    # 优先按酒馆项目声明的 packageManager 安装对应 pnpm 版本，
    # 避免 pnpm 版本与 SillyTavern 要求不匹配导致 install 直接失败
    if [[ -f "$HOME/$ST_DIR_NAME/package.json" ]]; then
        manager="$(jq -r '.packageManager // empty' "$HOME/$ST_DIR_NAME/package.json" 2>/dev/null || true)"
    fi

    if [[ -n "$manager" && "${manager%%@*}" == "pnpm" ]]; then
        ver="${manager#*@}"
        ver="${ver%%+*}"
        current="$(pnpm -v 2>/dev/null || true)"
        if [[ -n "$current" && "$current" == "$ver" ]]; then
            ok "pnpm 版本匹配：$current"
            return
        fi
        info "正在安装酒馆要求的 pnpm@$ver ..."
        if ! npm install -g "pnpm@$ver" < /dev/null; then
            die "pnpm 安装失败，请检查网络后重试。"
        fi
        ok "pnpm 安装完成：$(pnpm -v 2>/dev/null || echo '未知版本')"
        return
    fi

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
    ensure_pnpm_builds_allowed
    if ! (cd "$HOME/$ST_DIR_NAME" && pnpm install --dangerously-allow-all-builds < /dev/null); then
        warn "第一次安装失败，可能是网络波动，自动重试一次..."
        if ! (cd "$HOME/$ST_DIR_NAME" && pnpm install --dangerously-allow-all-builds < /dev/null); then
            die "酒馆依赖安装失败，请检查网络后重试。"
        fi
    fi
    ok "酒馆依赖全部安装完毕～"
}

# -----------------------------------------------------------------------------
# 下载管理器与更新工具
# -----------------------------------------------------------------------------
download_with_retry() {
    local url="$1" out="$2"
    local attempt
    for attempt in 1 2 3; do
        if curl -fsSL --connect-timeout 20 --retry 2 -o "$out" "$url"; then
            return 0
        fi
        warn "下载失败（第 ${attempt} 次），自动重试..."
        sleep 2
    done
    return 1
}

download_scripts() {
    info "正在下载管理器和更新工具..."
    if ! download_with_retry "$JH_MANAGER_URL" "$HOME/$MANAGER_FILENAME.tmp"; then
        die "下载管理器失败，请检查网络后重试。"
    fi
    if ! download_with_retry "$JH_UPDATE_URL" "$HOME/$UPDATE_FILENAME.tmp"; then
        die "下载更新工具失败，请检查网络后重试。"
    fi
    if ! download_with_retry "$JH_VERSION_URL" "$HOME/.jh_version"; then
        die "下载版本信息失败，请检查网络后重试。"
    fi

    # 下载后先做语法/非空校验，避免坏文件覆盖好文件
    if ! bash -n "$HOME/$MANAGER_FILENAME.tmp"; then
        rm -f "$HOME/$MANAGER_FILENAME.tmp" "$HOME/$UPDATE_FILENAME.tmp" "$HOME/.jh_version"
        die "下载的管理器脚本不完整，请重新运行安装。"
    fi
    if ! bash -n "$HOME/$UPDATE_FILENAME.tmp"; then
        rm -f "$HOME/$MANAGER_FILENAME.tmp" "$HOME/$UPDATE_FILENAME.tmp" "$HOME/.jh_version"
        die "下载的更新工具不完整，请重新运行安装。"
    fi
    if [[ ! -s "$HOME/.jh_version" ]]; then
        rm -f "$HOME/$MANAGER_FILENAME.tmp" "$HOME/$UPDATE_FILENAME.tmp" "$HOME/.jh_version"
        die "下载的版本信息为空，请重新运行安装。"
    fi

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
        bash "$HOME/$MANAGER_FILENAME" || true
    elif [[ -e /dev/tty ]]; then
        # 通过 curl | bash 安装时，stdin 是管道，这里强制接回当前终端
        bash "$HOME/$MANAGER_FILENAME" < /dev/tty || true
    else
        warn "安装已完成，但当前环境没有交互终端，无法自动打开管理系统。"
        warn "请手动运行：bash ~/jh_manager.sh"
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
