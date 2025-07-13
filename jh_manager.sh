#!/bin/bash
# SillyTavern Manager Script by 纪贺(ignite661)

# --- 配置区 ---
NODE_VERSION="18.17.1"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz"
NODE_DIR_NAME="node-v${NODE_VERSION}-linux-arm64"
TAVERN_DIR="/root/SillyTavern"
AUTOSTART_FLAG="/root/.autostart_enabled"

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# --- 功能函数 ---

function check_dependencies() {
    echo -e "${YELLOW}>> 正在初始化并检查运行环境，请稍候...${NC}"
    echo -e "${YELLOW}   这在首次运行时需要几分钟，您会看到系统更新的日志滚动，这是正常的。${NC}"
    # 移除 >/dev/null 2>&1，让用户看到进度
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y git curl build-essential python3

    if ! command -v node &>/dev/null || [[ $(node -v | cut -d'v' -f2) != "${NODE_VERSION}" ]]; then
        echo -e "${YELLOW}>> 首次运行，正在为您配置必要的 Node.js (v${NODE_VERSION}) 环境...${NC}"
        cd /root
        rm -rf "$NODE_DIR_NAME" "node.tar.xz"
        echo -e "   正在下载 Node.js，这可能需要一点时间..."
        curl -L -o node.tar.xz "$NODE_URL"
        echo -e "   正在解压和配置..."
        tar -xf node.tar.xz
        # 确保PATH只添加一次
        if ! grep -q "export PATH=\$PATH:/root/${NODE_DIR_NAME}/bin" /root/.bashrc; then
            echo "export PATH=\$PATH:/root/${NODE_DIR_NAME}/bin" >> /root/.bashrc
        fi
        export PATH=$PATH:/root/$NODE_DIR_NAME/bin
        rm node.tar.xz
        echo -e "${GREEN}>> 环境配置完成！${NC}"
        sleep 2
    fi
}


function start_tavern() {
    if [ ! -d "$TAVERN_DIR" ]; then
        echo -e "${RED}错误：SillyTavern 目录不存在。请先从主菜单安装。${NC}"
        sleep 3
        return
    fi
    cd "$TAVERN_DIR"
    echo -e "${GREEN}>> 正在启动 SillyTavern...${NC}"
    echo -e "您现在可以通过浏览器访问 ${CYAN}http://127.0.0.1:8000${NC}"
    echo -e "在 Termux 中，按 ${YELLOW}Ctrl + C${NC} 可以停止酒馆并返回管理菜单。"
    ./start.sh
    echo -e "${YELLOW}>> SillyTavern 已停止。${NC}"
    sleep 2
}

function install_tavern() {
    if [ -d "$TAVERN_DIR" ]; then
        echo -e "${YELLOW}检测到 SillyTavern 已安装。您想：${NC}"
        echo "1) 重新安装 (会删除旧数据！)"
        echo "2) 返回主菜单"
        read -p "请选择 [1-2]: " choice
        if [[ "$choice" == "1" ]]; then
            echo -e "${RED}正在删除旧的 SillyTavern...${NC}"
            rm -rf "$TAVERN_DIR"
        else
            return
        fi
    fi
    echo -e "${YELLOW}>> 正在从 GitHub 克隆 SillyTavern (release 分支)...${NC}"
    git clone https://github.com/SillyTavern/SillyTavern.git -b release "$TAVERN_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}>> SillyTavern 安装成功！${NC}"
    else
        echo -e "${RED}>> SillyTavern 安装失败！请检查网络和 GitHub 连接。${NC}"
    fi
    sleep 3
}

function update_tavern() {
    if [ ! -d "$TAVERN_DIR" ]; then
        echo -e "${RED}错误：SillyTavern 目录不存在。请先从主菜单安装。${NC}"
        sleep 3
        return
    fi
    cd "$TAVERN_DIR"
    echo -e "${YELLOW}>> 正在更新 SillyTavern...${NC}"
    git pull
    echo -e "${GREEN}>> 更新完成！${NC}"
    sleep 3
}

function manage_autostart() {
    if [ -f "$AUTOSTART_FLAG" ]; then
        echo -e "当前状态：开机自启 ${GREEN}已启用${NC}。"
        read -p "您想禁用开机自启吗？ (y/N): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            rm -f "$AUTOSTART_FLAG"
            echo -e "${GREEN}>> 开机自启已禁用。下次打开 Termux 将进入命令行。${NC}"
        fi
    else
        echo -e "当前状态：开机自启 ${RED}已禁用${NC}。"
        read -p "您想启用开机自启吗？ (y/N): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            touch "$AUTOSTART_FLAG"
            echo -e "${GREEN}>> 开机自启已启用。下次打开 Termux 将自动进入本面板。${NC}"
        fi
    fi
    sleep 3
}


function main_menu() {
    while true; do
        clear
        echo -e "${CYAN}--- 纪贺的酒馆管理系统 ---${NC}"
        echo -e "SillyTavern 状态: "
        if [ -d "$TAVERN_DIR" ]; then
            echo -e "  ${GREEN}已安装${NC} at ${TAVERN_DIR}"
        else
            echo -e "  ${RED}未安装${NC}"
        fi
        echo "--------------------------------"
        echo "1) 启动 SillyTavern"
        echo "2) 安装 / 重新安装 SillyTavern"
        echo "3) 更新 SillyTavern"
        echo "4) 高级选项 (管理开机自启)"
        echo "5) 退出管理面板 (返回 Termux 命令行)"
        echo -e "--------------------------------"
        read -p "请输入您的选择 [1-5]: " choice

        case $choice in
            1) start_tavern ;;
            2) install_tavern ;;
            3) update_tavern ;;
            4) manage_autostart ;;
            5) clear; echo "已退出管理面板。"; exit 0 ;;
            *) echo -e "${RED}无效输入，请重试。${NC}"; sleep 1 ;;
        esac
    done
}

# --- 脚本主入口 ---
check_dependencies
main_menu
