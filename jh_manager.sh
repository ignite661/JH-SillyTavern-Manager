#!/bin/bash
#
# =============================================================================
#  纪贺 SillyTavern 管理系统 (JH-Manager)
#  版本: v1.0.6
#  作者: 纪贺 (ignite661)
#  说明: 轻量、好用的酒馆管理界面
#
#  特点:
#  - 启动零网络请求，秒开不卡顿
#  - 所有检查/更新均为手动触发
#  - 支持备份 / 恢复酒馆数据
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# 路径配置
# -----------------------------------------------------------------------------
ST_DIR="$HOME/SillyTavern"
BACKUP_DIR="$HOME/SillyTavern_backups"
MANAGER_FILE="$HOME/jh_manager.sh"
UPDATE_SCRIPT="$HOME/update.sh"
VERSION_FILE="$HOME/.jh_version"

# -----------------------------------------------------------------------------
# 颜色
# -----------------------------------------------------------------------------
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_BLUE='\033[0;34m'
C_DIM='\033[2m'

info() { echo -e "${C_CYAN}$1${C_RESET}"; }
ok()   { echo -e "${C_GREEN}✅ $1${C_RESET}"; }
warn() { echo -e "${C_YELLOW}⚠️  $1${C_RESET}"; }
err()  { echo -e "${C_RED}❌ $1${C_RESET}" >&2; }

pause() {
    echo
    read -rsp $'按回车键返回菜单...' 
    echo
}

# -----------------------------------------------------------------------------
# 获取本地版本号（只读本地缓存，不联网）
# -----------------------------------------------------------------------------
get_local_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        head -n1 "$VERSION_FILE" 2>/dev/null || echo "未知版本"
    else
        echo "未知版本"
    fi
}

# -----------------------------------------------------------------------------
# 欢迎界面
# -----------------------------------------------------------------------------
show_banner() {
    local ver="$1"
    clear
    echo -e "${C_CYAN}"
    echo "   ╔══════════════════════════════════════════════╗"
    echo "   ║        🍷 纪贺 SillyTavern 管理器           ║"
    echo "   ║           你的酒馆，随时开张～               ║"
    echo "   ╚══════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo -e "${C_DIM}   JH-Manager $ver${C_RESET}"
    echo
}

# -----------------------------------------------------------------------------
# 检查酒馆是否已安装
# -----------------------------------------------------------------------------
is_st_installed() {
    [[ -d "$ST_DIR" && -f "$ST_DIR/package.json" ]]
}

# -----------------------------------------------------------------------------
# 检查酒馆是否在运行
# -----------------------------------------------------------------------------
is_st_running() {
    pgrep -f "node.*server.js" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# 允许 pnpm 运行依赖构建脚本（解决 ERR_PNPM_IGNORED_BUILDS）
# -----------------------------------------------------------------------------
ensure_pnpm_builds_allowed() {
    # pnpm 10.9+ 的构建许可必须写在项目 pnpm-workspace.yaml 里，
    # 写在 ~/.npmrc 不生效（那是导致 ERR_PNPM_IGNORED_BUILDS 的根因）
    local ws="$ST_DIR/pnpm-workspace.yaml"
    if [[ -f "$ws" ]]; then
        sed -i '/^dangerouslyAllowAllBuilds:/d' "$ws"
    fi
    echo "dangerouslyAllowAllBuilds: true" >> "$ws"
}

# -----------------------------------------------------------------------------
# 确保 pnpm 版本与酒馆项目要求一致（仅在更新/重装时联网调用）
# -----------------------------------------------------------------------------
ensure_pnpm() {
    ensure_pnpm_builds_allowed

    if [[ ! -f "$ST_DIR/package.json" ]]; then
        return 0
    fi

    local manager="" ver="" current=""
    manager="$(jq -r '.packageManager // empty' "$ST_DIR/package.json" 2>/dev/null || true)"
    if [[ -z "$manager" || "${manager%%@*}" != "pnpm" ]]; then
        return 0
    fi

    ver="${manager#*@}"
    ver="${ver%%+*}"
    current="$(pnpm -v 2>/dev/null || true)"
    if [[ -n "$current" && "$current" == "$ver" ]]; then
        return 0
    fi

    info "检测到酒馆需要 pnpm@$ver，正在自动切换..."
    if ! npm install -g "pnpm@$ver" < /dev/null; then
        err "自动切换 pnpm 版本失败，请检查网络。"
        return 1
    fi
    ok "pnpm 已切换为 $ver"
}

# -----------------------------------------------------------------------------
# 1. 打开酒馆
# -----------------------------------------------------------------------------
start_st() {
    clear
    if ! is_st_installed; then
        warn "还没找到酒馆目录，请先运行安装脚本哦～"
        pause
        return
    fi
    if is_st_running; then
        warn "酒馆已经在运行啦，不要重复开～"
        pause
        return
    fi

    echo -e "${C_YELLOW}🍷 正在帮你打开酒馆...${C_RESET}"
    echo "启动成功后请保持本窗口运行，按 Ctrl+C 可关闭酒馆。"
    echo
    echo -e "  手机浏览器访问：${C_GREEN}http://127.0.0.1:8000${C_RESET}"
    echo
    cd "$ST_DIR"
    # 用 || true 避免酒馆启动失败/被 Ctrl+C 时整个管理器跟着退出
    NODE_OPTIONS="--max-old-space-size=4096" pnpm start || true
    echo
    warn "酒馆已关闭。"
    pause
}

# -----------------------------------------------------------------------------
# 2. 检查酒馆更新
# -----------------------------------------------------------------------------
update_st() {
    clear
    if [[ ! -d "$ST_DIR/.git" ]]; then
        warn "没有找到酒馆的 Git 仓库，暂时无法更新。"
        pause
        return
    fi

    if is_st_running; then
        warn "酒馆正在运行，请先关闭酒馆再更新。"
        pause
        return
    fi

    echo -e "${C_YELLOW}🔄 正在帮你拉取最新版酒馆，稍等片刻...${C_RESET}"
    echo

    # 更新前先确保 pnpm 版本匹配（联网操作）
    if ! ensure_pnpm; then
        pause
        return
    fi

    # --rebase --autostash: 有本地小改动也能自动暂存后更新，减少更新失败
    if ! (cd "$ST_DIR" && git pull --rebase --autostash); then
        err "酒馆更新失败，检查网络或本地冲突后再试试？"
        pause
        return
    fi

    echo
    info "代码更新完成，正在同步依赖..."
    # 更新后 package.json 可能变化，再确保一次 pnpm 版本
    if ! ensure_pnpm; then
        pause
        return
    fi

    if ! (cd "$ST_DIR" && pnpm install --dangerously-allow-all-builds < /dev/null); then
        warn "依赖同步失败，自动重试一次..."
        if ! (cd "$ST_DIR" && pnpm install --dangerously-allow-all-builds < /dev/null); then
            err "依赖同步失败，可以稍后选“重新安装依赖”。"
            pause
            return
        fi
    fi

    ok "酒馆已经更新到最新版～"
    pause
}

# -----------------------------------------------------------------------------
# 3. 重新安装依赖
# -----------------------------------------------------------------------------
reinstall_deps() {
    clear
    if ! is_st_installed; then
        warn "还没找到酒馆目录，无法重装依赖。"
        pause
        return
    fi

    if is_st_running; then
        warn "酒馆正在运行，请先关闭酒馆再重装依赖。"
        pause
        return
    fi

    warn "这一步会删除 node_modules 并重新安装，可能需要几分钟。"
    read -rp "确定继续吗？(y/n): " confirm
    confirm="${confirm//[[:space:]]/}"
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "好，已取消。"
        pause
        return
    fi

    echo
    if ! ensure_pnpm; then
        pause
        return
    fi

    echo "正在删除旧依赖..."
    rm -rf "$ST_DIR/node_modules"
    echo "正在安装新依赖..."
    if ! (cd "$ST_DIR" && pnpm install --dangerously-allow-all-builds < /dev/null); then
        warn "依赖安装失败，自动重试一次..."
        if ! (cd "$ST_DIR" && pnpm install --dangerously-allow-all-builds < /dev/null); then
            err "依赖安装失败，请检查网络后重试。"
            pause
            return
        fi
    fi

    ok "依赖重装完成～"
    pause
}

# -----------------------------------------------------------------------------
# 4. 备份数据
# -----------------------------------------------------------------------------
backup_data() {
    clear
    if ! is_st_installed; then
        warn "还没找到酒馆目录，无法备份。"
        pause
        return
    fi

    if is_st_running; then
        warn "酒馆正在运行，建议先关闭再备份（数据更完整）。"
        read -rp "仍然继续备份吗？(y/n): " confirm
        confirm="${confirm//[[:space:]]/}"
        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
            echo "好，已取消。"
            pause
            return
        fi
    fi

    mkdir -p "$BACKUP_DIR"
    local stamp
    stamp="$(date +%Y%m%d_%H%M%S)"
    local backup_file="$BACKUP_DIR/SillyTavern_备份_${stamp}.tar.gz"

    local items=()
    # 新版酒馆数据在 data/default-user
    if [[ -d "$ST_DIR/data/default-user" ]]; then
        items+=("data/default-user")
    else
        # 旧版酒馆数据在 public 下
        local sub
        for sub in characters chats worlds groups "group chats" "OpenAI Settings" "User Avatars" backgrounds plugins; do
            [[ -e "$ST_DIR/public/$sub" ]] && items+=("public/$sub")
        done
        [[ -f "$ST_DIR/public/settings.json" ]] && items+=("public/settings.json")
    fi

    if [[ ${#items[@]} -eq 0 ]]; then
        warn "没有找到可备份的数据。"
        pause
        return
    fi

    echo -e "${C_YELLOW}📦 正在帮你打包数据，请稍等...${C_RESET}"
    if ! tar -C "$ST_DIR" -czf "$backup_file" "${items[@]}"; then
        err "备份失败，请检查存储空间。"
        pause
        return
    fi

    ok "备份完成，文件在这里："
    echo -e "  ${C_GREEN}$backup_file${C_RESET}"
    pause
}

# -----------------------------------------------------------------------------
# 5. 恢复数据
# -----------------------------------------------------------------------------
restore_data() {
    clear
    if ! is_st_installed; then
        warn "还没找到酒馆目录，无法恢复。"
        pause
        return
    fi

    if is_st_running; then
        warn "酒馆正在运行，请先关闭酒馆再恢复数据。"
        pause
        return
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        warn "还没有备份目录，先备份一次再恢复吧～"
        pause
        return
    fi

    mapfile -t backups < <(find "$BACKUP_DIR" -maxdepth 1 -name 'SillyTavern_备份_*.tar.gz' 2>/dev/null | sort -r)
    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "没有找到备份文件。"
        pause
        return
    fi

    echo -e "${C_BLUE}📂 可用的备份：${C_RESET}"
    local i
    for i in "${!backups[@]}"; do
        echo "  $((i + 1)). $(basename "${backups[$i]}")"
    done
    echo "  0. 取消"
    echo
    read -rp "请输入备份编号: " choice
    choice="${choice//[[:space:]]/}"

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 || "$choice" -gt "${#backups[@]}" ]]; then
        echo "好，已取消。"
        pause
        return
    fi

    local target="${backups[$((choice - 1))]}"
    echo
    warn "恢复会覆盖当前酒馆数据：$(basename "$target")"
    read -rp "确定恢复吗？(y/n): " confirm
    confirm="${confirm//[[:space:]]/}"
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "好，已取消。"
        pause
        return
    fi

    echo "正在校验备份文件..."
    if ! tar -tzf "$target" >/dev/null 2>&1; then
        err "备份文件校验失败，可能已损坏。"
        pause
        return
    fi

    echo "正在恢复数据..."
    if ! tar -xzf "$target" -C "$ST_DIR"; then
        err "恢复失败，备份文件可能已损坏。"
        pause
        return
    fi

    ok "恢复完成～ 启动酒馆看看吧！"
    pause
}

# -----------------------------------------------------------------------------
# 6. 检查脚本更新
# -----------------------------------------------------------------------------
update_scripts() {
    clear
    if [[ -x "$UPDATE_SCRIPT" ]]; then
        if ! bash "$UPDATE_SCRIPT"; then
            err "脚本更新过程出错，请稍后重试。"
            pause
            return
        fi
    else
        warn "没有找到 update.sh，尝试直接下载..."
        local raw_url="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/update.sh"
        if curl -fsSL -o "$UPDATE_SCRIPT.tmp" "$raw_url"; then
            mv -f "$UPDATE_SCRIPT.tmp" "$UPDATE_SCRIPT"
            chmod +x "$UPDATE_SCRIPT"
            if ! bash "$UPDATE_SCRIPT"; then
                err "脚本更新过程出错，请稍后重试。"
                pause
                return
            fi
        else
            err "下载更新工具失败，请检查网络。"
            rm -f "$UPDATE_SCRIPT.tmp"
            pause
            return
        fi
    fi
    echo
    info "脚本更新完成，重启管理系统后生效。"
    pause
}

# -----------------------------------------------------------------------------
# 主菜单
# -----------------------------------------------------------------------------
main_menu() {
    local ver
    ver="$(get_local_version)"

    while true; do
        show_banner "$ver"

        echo -e " ${C_GREEN}1.${C_RESET} 打开酒馆"
        echo -e " ${C_BLUE}2.${C_RESET} 检查酒馆更新"
        echo -e " ${C_YELLOW}3.${C_RESET} 重新安装依赖"
        echo -e " ${C_GREEN}4.${C_RESET} 备份数据"
        echo -e " ${C_BLUE}5.${C_RESET} 恢复数据"
        echo -e " ${C_YELLOW}6.${C_RESET} 检查脚本更新"
        echo -e " ${C_RED}q.${C_RESET} 退出管理系统"
        echo
        echo -e "${C_CYAN}----------------------------------------------${C_RESET}"

        local choice
        read -rp "请选择 [1-6, q]: " choice
        choice="${choice//[[:space:]]/}"

        case "$choice" in
            1) start_st ;;
            2) update_st ;;
            3) reinstall_deps ;;
            4) backup_data ;;
            5) restore_data ;;
            6) update_scripts ;;
            q|Q)
                echo
                echo -e "${C_YELLOW}下次见，酒馆等你回来～${C_RESET}"
                exit 0
                ;;
            *)
                warn "无效选项，重新选一个吧～"
                sleep 1
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# 启动
# -----------------------------------------------------------------------------
main_menu
