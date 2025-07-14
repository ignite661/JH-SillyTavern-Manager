#!/bin/bash

# ==============================================================================
# SillyTavern 启动/管理脚本 (JH-Manager v3.1 - UI美化版)
#
# 作者: 纪贺 (ignite661)
#
# v3.1: 严格基于最稳定的 v3.0 原生版，仅进行界面美化和文字优化。
#       核心功能和命令未做任何改动，确保100%的稳定性。
# ==============================================================================

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

# --- 全局变量  ---
ST_DIR_NAME="SillyTavern"

# --- 函数 (v3.0) ---
start_st() {
    clear
    echo -e "${C_YELLOW}正在启动 SillyTavern (原生模式)...${C_RESET}"
    echo -e "请等待约 10-30 秒，启动成功后会显示监听端口。"
    echo -e "届时请在手机浏览器中访问: ${C_GREEN}http://127.0.0.1:8000${C_RESET}"
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    
    if [ -d "$ST_DIR_NAME" ]; then
        cd "$ST_DIR_NAME" && pnpm start
    else
        echo -e "${C_RED}错误: 未找到 SillyTavern 目录！${C_RESET}"
    fi
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    echo -e "${C_RED}SillyTavern 已关闭或启动失败。${C_RESET}"
}

update_st() {
    clear
    echo -e "${C_YELLOW}正在更新 SillyTavern...${C_RESET}"
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    if [ -d "$ST_DIR_NAME" ]; then
        cd "$ST_DIR_NAME" && git pull && cd ..
    else
        echo -e "${C_RED}错误: 未找到 SillyTavern 目录！${C_RESET}"
    fi
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}更新完成。如果看到 'Already up to date.' 说明已是最新版。${C_RESET}"
}

reinstall_deps() {
    clear
    echo -e "${C_YELLOW}正在使用 pnpm 重新安装依赖... (这可能需要几分钟)${C_RESET}"
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    if [ -d "$ST_DIR_NAME" ]; then
        cd "$ST_DIR_NAME"
        echo "正在删除旧依赖..."
        rm -rf node_modules
        echo "正在安装新依赖..."
        pnpm install
        cd ..
        echo -e "${C_GREEN}依赖重装完成。${C_RESET}"
    else
        echo -e "${C_RED}错误: 未找到 SillyTavern 目录！${C_RESET}"
    fi
     echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
}

# --- 主菜单  ---
while true; do
    clear
    echo -e "${C_CYAN}========================================"
    echo -e "  ${C_WHITE}纪贺 SillyTavern 管理器 (v3.1 UI版)${C_RESET}"
    echo -e "${C_CYAN}========================================"
    echo -e " ${C_GREEN}1. 启动 SillyTavern${C_RESET}"
    echo -e " ${C_BLUE}2. 更新 SillyTavern${C_RESET}"
    echo -e " ${C_YELLOW}3. 重新安装依赖 (解决更新后问题)${C_RESET}"
    echo -e " ${C_RED}q. 退出${C_RESET}"
    echo -e "----------------------------------------"
    read -p "请输入选项 [1-3, q]: " choice

    case $choice in
        1)
            start_st
            read -p "按 Enter键 返回主菜单..."
            ;;
        2)
            update_st
            read -p "按 Enter键 返回主菜单..."
            ;;
        3)
            reinstall_deps
            read -p "按 Enter键 返回主菜单..."
            ;;
        q|Q)
            echo -e "${C_YELLOW}正在退出...${C_RESET}"
            break
            ;;
        *)
            echo -e "${C_RED}无效选项，请重试。${C_RESET}"
            sleep 1
            ;;
    esac
done
