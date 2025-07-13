#!/bin/bash

# ==============================================================================
# SillyTavern 启动/管理脚本 (JH-Manager v4.0 - 经典UI增强版)
#
# 作者: 纪贺科技 (ignite661) & 您
#
# v4.0: 回归您设计的经典架构，并融合了更美观的用户界面和更清晰的提示。
#       这是稳定结构和优秀体验的完美结合。
# ==============================================================================

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

# --- 全局变量 ---
TAVERN_DIR="SillyTavern"

# --- 功能函数 ---
show_menu() {
    clear
    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo -e "${C_WHITE}         SillyTavern 智能管理器 v4.0          ${C_RESET}"
    echo -e "${C_WHITE}                  by 纪贺                  ${C_RESET}"
    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo
    echo -e "  ${C_GREEN}1. 启动 SillyTavern${C_RESET}"
    echo -e "  ${C_BLUE}2. 更新 SillyTavern 到最新版${C_RESET}"
    echo -e "  ${C_BLUE}3. 重新安装依赖 (强制模式)${C_RESET}"
    echo
    echo -e "  ${C_YELLOW}q. 退出管理器${C_RESET}"
    echo -e "${C_CYAN}---------------------------------------------------${C_RESET}"
}

start_tavern() {
    echo -e "\n${C_YELLOW}>>> 正在尝试启动 SillyTavern...${C_RESET}"
    if [ ! -d "$TAVERN_DIR" ]; then
        echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}"
    elif [ ! -f "$TAVERN_DIR/server.js" ]; then
        echo -e "\n${C_RED}错误：找不到启动文件 server.js！可能是安装不完整。${C_RESET}"
    else
        cd "$TAVERN_DIR"
        echo -e "${C_WHITE}启动成功后，请在浏览器访问: http://127.0.0.1:8000 或 http://localhost:8000${C_RESET}"
        echo -e "${C_WHITE}在 Termux 中按 Ctrl+C 即可停止运行。${C_RESET}"
        echo -e "${C_CYAN}-------------------- LOGS --------------------${C_RESET}"
        pnpm start
        echo -e "${C_CYAN}----------------------------------------------${C_RESET}"
        echo -e "\n${C_RED}SillyTavern 已关闭或启动失败。${C_RESET}"
    fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}"
    read
}

update_tavern() {
    echo -e "\n${C_YELLOW}>>> 正在更新 SillyTavern...${C_RESET}"
    if [ -d "$TAVERN_DIR" ]; then
        cd "$TAVERN_DIR"
        git pull
        echo -e "\n${C_GREEN}更新完成！如果出现问题，建议使用选项3重新安装依赖。${C_RESET}"
    else
        echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}"
    fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}"
    read
}

reinstall_deps() {
    echo -e "\n${C_YELLOW}>>> 正在强制重新安装依赖...${C_RESET}"
    if [ -d "$TAVERN_DIR" ]; then
        cd "$TAVERN_DIR"
        echo "  正在删除旧的依赖 (node_modules)..."
        rm -rf node_modules
        echo "  正在使用 pnpm 重新安装，请耐心等待..."
        pnpm install
        echo -e "\n${C_GREEN}依赖重新安装完成！${C_RESET}"
    else
        echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}"
    fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}"
    read
}

# --- 主循环 ---
while true; do
    show_menu
    read -p "请输入选项 [1-3, q]: " choice

    case $choice in
        1) start_tavern ;;
        2) update_tavern ;;
        3) reinstall_deps ;;
        q|Q)
            echo -e "\n${C_YELLOW}正在退出... 感谢使用！${C_RESET}"
            break ;;
        *)
            echo -e "\n${C_RED}无效的输入，请重新选择。${C_RESET}"
            sleep 1 ;;
    esac
done
