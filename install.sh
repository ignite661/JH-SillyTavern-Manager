#!/bin/bash
#
# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v6.5.1 - 修复版)
#
# 作者: JiHe (纪贺)
#
# v6.5 更新:
# - 修复: 首次安装后自动进入UI时，因stdin污染导致的无限循环bug。
# - 修复: 为 'pkg update' 也添加了--force-confold参数，实现完全无交互。
# ==============================================================================

# 脚本出错时立即退出
set -e

# --- 脚本配置 ---
JH_MANAGER_URL="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/jh_manager.sh"
MANAGER_FILENAME="jh_manager.sh"
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"

# -- 颜色定义 --
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 安装流程开始 ---

clear
echo -e "${CYAN}=============================================${NC}"
echo -e "${CYAN}   欢迎使用 纪贺SillyTavern 一键安装脚本   ${NC}"
echo -e "${CYAN}=============================================${NC}"
echo

echo -e "${YELLOW}------------------- 重要声明 (请仔细阅读) -------------------${NC}"
echo -e "本脚本由作者 ${GREEN}纪贺(ignite661)${NC} 开发，完全 ${GREEN}免费${NC} 并遵循开源精神。"
echo -e "严禁任何人将此脚本及管理器用于任何形式的 ${RED}商业用途${NC} 或 ${RED}倒卖行为${NC}。"
echo
echo -e "${RED}!!! 警告: 如果您是付费购买得到的本脚本，说明您已被骗！${NC}"
echo -e "${RED}          请立即向卖家要求退款，并抵制这种可耻的盗卖行为！${NC}"
echo
echo -e "Bug反馈或建议，请联系作者邮箱: ${GREEN}wjj373247085@163.com${NC}"
echo -e "感谢您的信任与使用！"
echo -e "${YELLOW}-------------------------------------------------------------${NC}"
echo
echo -e "声明展示完毕，安装将在 8 秒后自动开始..."
sleep 8


echo -e "${YELLOW}本脚本将全自动为您在Termux中部署SillyTavern...${NC}"
sleep 3

# --- 步骤 1: 准备Termux环境 ---
echo
echo -e "${CYAN}[步骤 1/5] 正在全自动准备 Termux 运行环境...${NC}"
echo "这将更新软件包并安装必要组件，全程无需手动干预。"
pkg update -y -o Dpkg::Options::="--force-confold" && pkg install -y -o Dpkg::Options::="--force-confold" git nodejs-lts curl jq

# 验证核心组件是否成功安装
if ! command -v git &> /dev/null || ! command -v node &> /dev/null; then
    echo -e "${RED}致命错误: 核心组件 git 或 nodejs 未能成功安装！${NC}"
    exit 1
fi
echo -e "${GREEN}✔ 环境准备就绪！${NC}"
echo -n "Node.js 版本: "; node -v
echo

# --- 步骤 2: 克隆SillyTavern仓库 ---
echo -e "${CYAN}[步骤 2/5] 正在从GitHub克隆SillyTavern主程序...${NC}"
if [ -d "$HOME/$ST_DIR_NAME" ]; then
    echo -e "${YELLOW}检测到 SillyTavern 目录已存在，跳过克隆。${NC}"
else
    cd "$HOME"
    if git clone ${ST_REPO_URL} ${ST_DIR_NAME}; then
        echo -e "${GREEN}✔ SillyTavern 主程序克隆成功！${NC}"
    else
        echo -e "${RED}错误：从GitHub克隆SillyTavern失败！请检查网络。${NC}"
        exit 1
    fi
fi
echo

# --- 步骤 3: 全局安装pnpm ---
echo -e "${CYAN}[步骤 3/5] 正在使用npm全局安装pnpm包管理器...${NC}"
if npm i -g pnpm < /dev/null; then  # <--- 在这里添加了 < /dev/null
    echo -e "${GREEN}✔ pnpm 安装成功！${NC}"
else
    echo -e "${RED}错误：pnpm 安装失败！${NC}"
    exit 1
fi
echo

# --- 步骤 4: 安装SillyTavern依赖 ---
echo -e "${CYAN}[步骤 4/5] 正在进入SillyTavern目录并安装依赖...${NC}"
cd "$HOME/$ST_DIR_NAME"
if pnpm install; then
    echo -e "${GREEN}✔ SillyTavern 依赖项全部安装完毕！${NC}"
else
    echo -e "${RED}错误：依赖安装失败！${NC}"
fi
cd "$HOME"
echo

# --- 步骤 5: 下载管理器并设置自动启动 ---
echo -e "${CYAN}[步骤 5/5] 正在下载管理器并设置沉浸式启动...${NC}"
if curl -fsSL -o "$HOME/$MANAGER_FILENAME" "${JH_MANAGER_URL}"; then
    chmod +x "$HOME/$MANAGER_FILENAME"
    echo -e "${GREEN}✔ 纪贺管理器下载成功！${NC}"

    if ! grep -q "$HOME/$MANAGER_FILENAME" "$HOME/.bashrc"; then
        echo -e "\n# 自动启动纪贺SillyTavern管理器\n$HOME/$MANAGER_FILENAME" >> "$HOME/.bashrc"
        echo -e "${GREEN}✔ 已成功设置“沉浸式启动”！${NC}"
    else
        echo -e "${YELLOW}检测到自动启动设置已存在，无需重复配置。${NC}"
    fi
else
    echo -e "${RED}致命错误：无法从 GitHub 下载您的管理器脚本！${NC}"
    exit 1
fi
echo

# --- 安装完成，最终提示 ---
clear
echo -e "${GREEN}🎉🎉🎉 恭喜！SillyTavern 已在您的Termux中完美部署！ 🎉🎉🎉${NC}"
echo
echo -e "已为您开启了 ${YELLOW}沉浸式启动模式${NC}！"
echo -e "从现在开始，您每次 ${GREEN}点击Termux应用图标${NC}，就会 ${GREEN}直接进入SillyTavern管理器界面${NC}。"
echo
echo -e "\n${YELLOW}首次安装完成，正在自动进入管理器，请稍候...${NC}"
sleep 5

# <--- 终极修复！--->
# 强制将管理器的输入重定向到当前终端(/dev/tty)，防止因管道符导致的stdin污染
"$HOME/$MANAGER_FILENAME" < /dev/tty

exit 0
