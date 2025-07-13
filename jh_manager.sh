#!/bin/bash

# ==============================================================================
# SillyTavern Termux 管理脚本 (JH-Manager v2.0 - 绕行版)
#
# 此版本与 install.sh v2.0 配套使用。
# - Node.js 路径被硬编码以适应新的部署方式。
# - 更新操作使用 Termux 的 git。
# ==============================================================================

# -- 配置 --
ST_DIR_IN_UBUNTU="/root/SillyTavern"
# Node.js 版本和目录 - 必须与 install.sh 中的定义一致
NODE_VERSION="v20.12.2"
NODE_DIR_NAME="node-${NODE_VERSION}-linux-arm64"
NODE_PATH_IN_UBUNTU="/root/${NODE_DIR_NAME}/bin"
AUTOSTART_FLAG_FILE=".st_autostart_enabled"

# -- 颜色定义 --
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- 核心函数 ---

# 在 Ubuntu 容器中执行命令的辅助函数
# 关键: 自动为命令注入正确的 Node.js 路径
run_in_ubuntu() {
    local cmd_to_run=$1
    proot-distro login ubuntu --shared-tmp -- bash -c "export PATH=${NODE_PATH_IN_UBUNTU}:\$PATH && ${cmd_to_run}"
}

# 检查 SillyTavern 是否已安装
check_st_installed() {
    local ubuntu_root
    ubuntu_root=$(proot-distro path ubuntu)
    if [ ! -d "${ubuntu_root}${ST_DIR_IN_UBUNTU}" ]; then
        echo -e "${RED}错误: 未在 Ubuntu 容器中找到 SillyTavern 目录。${NC}"
        echo "请先运行 'install.sh' 进行安装。"
        exit 1
    fi
}

# 检查 SillyTavern 运行状态
check_st_status() {
    # 检查 node server.js 进程
    if pgrep -f "node.*server.js" > /dev/null; then
        return 0 # 正在运行
    else
        return 1 # 未运行
    fi
}

# 启动 SillyTavern
start_st() {
    if check_st_status; then
        echo -e "${YELLOW}SillyTavern 已经在运行中。${NC}"
    else
        echo "正在启动 SillyTavern..."
        # 使用 nohup 和 & 实现后台运行
        run_in_ubuntu "cd ${ST_DIR_IN_UBUNTU} && nohup npm start &"
        sleep 5 # 等待启动
        if check_st_status; then
            echo -e "${GREEN}SillyTavern 启动成功！${NC}"
            echo "请在浏览器中访问: http://127.0.0.1:8000"
        else
            echo -e "${RED}SillyTavern 启动失败。请检查日志。${NC}"
        fi
    fi
}

# 停止 SillyTavern
stop_st() {
    if check_st_status; then
        echo "正在停止 SillyTavern..."
        # 精准查杀
        pkill -f "node.*server.js"
        sleep 2
        echo -e "${GREEN}SillyTavern 已停止。${NC}"
    else
        echo -e "${YELLOW}SillyTavern 当前未运行。${NC}"
    fi
}

# 更新 SillyTavern
update_st() {
    echo "正在更新 SillyTavern..."
    stop_st # 更新前先停止
    local ubuntu_root
    ubuntu_root=$(proot-distro path ubuntu)
    # 使用 Termux 的 git 直接操作 Ubuntu 文件系统
    cd "${ubuntu_root}${ST_DIR_IN_UBUNTU}" || { echo "无法进入 ST 目录"; exit 1; }
    git pull
    echo "更新完成。正在重新安装依赖..."
    run_in_ubuntu "cd ${ST_DIR_IN_UBUNTU} && npm install"
    echo -e "${GREEN}SillyTavern 更新并安装依赖完成。${NC}"
    echo "您可以现在启动 SillyTavern。"
}

# 管理开机自启
manage_autostart() {
    if [ -f "$HOME/$AUTOSTART_FLAG_FILE" ]; then
        echo "当前开机自启状态: ${GREEN}已启用${NC}"
        read -p "是否要禁用开机自启? (y/N): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            rm -f "$HOME/$AUTOSTART_FLAG_FILE"
            echo -e "${GREEN}开机自启已禁用。${NC}"
        fi
    else
        echo "当前开机自启状态: ${RED}已禁用${NC}"
        read -p "是否要启用开机自启? (y/N): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            touch "$HOME/$AUTOSTART_FLAG_FILE"
            echo -e "${GREEN}开机自启已启用。${NC}"
            echo "请确保已安装并授权 Termux:Boot 应用。"
        fi
    fi
}

# Termux:Boot 的入口逻辑
handle_boot_start() {
    if [ -f "$HOME/$AUTOSTART_FLAG_FILE" ]; then
        echo "Termux:Boot 检测到自启标志，正在启动 SillyTavern..."
        start_st
    fi
    # 如果没有标志文件，则静默退出
}


# --- 主程序 ---

# 如果脚本以 "boot" 参数运行，则执行自启逻辑
if [ "$1" == "boot" ]; then
    handle_boot_start
    exit 0
fi


# 主菜单
check_st_installed
while true; do
    clear
    echo "纪贺科技 SillyTavern 管理器 v2.0 (绕行版)"
    echo "----------------------------------------"
    if check_st_status; then
        echo -e "状态: ${GREEN}正在运行${NC}"
    else
        echo -e "状态: ${RED}未运行${NC}"
    fi
    echo "----------------------------------------"
    echo "1. 启动 SillyTavern"
    echo "2. 停止 SillyTavern"
    echo "3. 更新 SillyTavern (git pull & npm install)"
    echo "4. 管理开机自启"
    echo "5. 退出"
    echo "----------------------------------------"
    read -p "请输入选项 [1-5]: " choice

    case $choice in
        1) start_st ;;
        2) stop_st ;;
        3) update_st ;;
        4) manage_autostart ;;
        5) exit 0 ;;
        *) echo -e "${RED}无效选项，请重试。${NC}" ;;
    esac
    echo -e "\n按任意键返回主菜单..."
    read -n 1 -s -r
done
