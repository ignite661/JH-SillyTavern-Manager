#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

ST_DIR_NAME="SillyTavern"
ST_PATH="$HOME/$ST_DIR_NAME"

start_st() {
    clear
    echo -e "${C_YELLOW}正在启动 SillyTavern...${C_RESET}"
    echo -e "请等待约 10-30 秒，启动成功后会显示监听端口。"
    echo -e "届时请在手机浏览器中访问: ${C_GREEN}http://127.0.0.1:8000${C_RESET}"
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    
    if [ -d "$ST_PATH" ]; then
        cd "$ST_PATH" && pnpm start
    else
        echo -e "${C_RED}错误: 未找到 SillyTavern 目录 ($ST_PATH)！${C_RESET}"
    fi
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    echo -e "${C_RED}SillyTavern 已关闭或启动失败。${C_RESET}"
}

update_st() {
    clear
    echo -e "${C_YELLOW}正在更新 SillyTavern 并安装新依赖...${C_RESET}"
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    if [ -d "$ST_PATH" ]; then
        cd "$ST_PATH"
        echo "--> 正在从 GitHub 拉取最新代码..."
        if git pull; then
            echo -e "${C_GREEN}代码更新成功。${C_RESET}"
            echo
            echo "--> 正在检查并安装依赖..."
            pnpm install
        else
            echo -e "${C_RED}代码拉取失败！请检查网络。${C_RESET}"
        fi
        cd "$HOME"
    else
        echo -e "${C_RED}错误: 未找到 SillyTavern 目录 ($ST_PATH)！${C_RESET}"
    fi
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}更新流程执行完毕。${C_RESET}"
}

reinstall_deps() {
    clear
    echo -e "${C_YELLOW}正在强制重装所有依赖... (这可能需要几分钟)${C_RESET}"
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    if [ -d "$ST_PATH" ]; then
        cd "$ST_PATH"
        echo "--> 正在删除旧的依赖文件夹 (node_modules)..."
        rm -rf node_modules
        echo "--> 正在全新安装所有依赖..."
        pnpm install
        cd "$HOME"
    else
        echo -e "${C_RED}错误: 未找到 SillyTavern 目录 ($ST_PATH)！${C_RESET}"
    fi
    echo -e "${C_CYAN}--------------------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}依赖重装完成。${C_RESET}"
}

while true; do
    clear
    echo -e "${C_CYAN}========================================"
    echo -e "  ${C_WHITE}纪贺 SillyTavern 管理器 (v3.3版)${C_RESET}"
    echo -e "${C_CYAN}========================================"
    echo -e " ${C_YELLOW}本程序完全免费 | Bug反馈: wjj373247085@163.com${C_RESET}"
    echo -e "----------------------------------------"
    echo -e " ${C_GREEN}1. 启动 SillyTavern${C_RESET}"
    echo -e " ${C_BLUE}2. 更新程序 (代码+依赖)${C_RESET}"
    echo -e " ${C_YELLOW}3. 强制重装依赖 (解决疑难杂症)${C_RESET}"
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
