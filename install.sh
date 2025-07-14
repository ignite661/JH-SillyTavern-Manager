#!/bin/bash
#
# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v1.2)
#
# 作者: JiHe (纪贺) 
#
# 特性:
# - 一键执行: 将所有繁琐步骤自动化，真正实现零基础安装。
# - 全程自动: 安装过程无需任何手动确认，避免中断。
# - 沉浸式体验: 安装完成后，每次打开Termux都将自动进入管理器界面。
# - 无缝衔接: 首次安装成功后，直接进入管理器，无需额外操作。
# - 智能检查: 自动检测SillyTavern是否已安装，避免重复操作。
# - 健壮可靠: 增加了关键步骤的错误检查，确保安装流程顺利。
# ==============================================================================

# 脚本出错时立即退出
set -e

# --- 脚本配置 ---
# 请确保此URL指向您最新的管理器脚本
JH_MANAGER_URL="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/jh_manager_native_v3.1.sh" 
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"

# -- 颜色定义，让输出更美观 --
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- 安装流程开始 ---

clear
echo -e "${CYAN}=============================================${NC}"
echo -e "${CYAN}   欢迎使用 纪贺SillyTavern 一键安装脚本   ${NC}"
echo -e "${CYAN}=============================================${NC}"
echo
echo -e "${YELLOW}本脚本将全自动为您在Termux中部署SillyTavern...${NC}"
sleep 3

# --- 步骤 1: 准备Termux环境 ---
echo
echo -e "${CYAN}[步骤 1/5] 正在全自动准备 Termux 运行环境...${NC}"
echo "这将更新软件包列表并安装必要组件（git, nodejs, curl, jq）。"
# 使用非交互模式，避免任何手动确认弹窗
DEBIAN_FRONTEND=noninteractive pkg update -y && DEBIAN_FRONTEND=noninteractive pkg install -y git nodejs-lts curl jq

# 验证核心组件是否成功安装
if ! command -v git &> /dev/null || ! command -v node &> /dev/null; then
    echo -e "${RED}致命错误: 核心组件 git 或 nodejs 未能成功安装！${NC}"
    echo -e "${RED}请检查您的网络连接或Termux源设置，然后重试。${NC}"
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
    # 切换到主目录（~）进行克隆
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
if npm i -g pnpm; then
    echo -e "${GREEN}✔ pnpm 安装成功！${NC}"
else
    echo -e "${RED}错误：pnpm 安装失败！${NC}"
    exit 1
fi
echo

# --- 步骤 4: 安装SillyTavern依赖 ---
echo -e "${CYAN}[步骤 4/5] 正在进入SillyTavern目录并安装依赖...${NC}"
# 确保在正确的目录下执行
cd "$HOME/$ST_DIR_NAME"
if pnpm install; then
    echo -e "${GREEN}✔ SillyTavern 依赖项全部安装完毕！${NC}"
else
    echo -e "${RED}错误：依赖安装失败！这可能是网络问题或pnpm错误。${NC}"
    echo -e "${YELLOW}您可以稍后在管理器中尝试“重新安装依赖”。${NC}"
    # 这里不退出，让用户有机会用管理器修复
fi
# 返回主目录
cd "$HOME"
echo

# --- 步骤 5: 下载管理器并设置自动启动 ---
echo -e "${CYAN}[步骤 5/5] 正在下载管理器并设置沉浸式启动...${NC}"
if curl -fsSL -o "$HOME/jh_manager_native.sh" "${JH_MANAGER_URL}"; then
    chmod +x "$HOME/jh_manager_native.sh"
    echo -e "${GREEN}✔ 纪贺管理器下载成功！${NC}"

    # 核心步骤：在 ~/.bashrc 中添加自动启动命令
    # 为了防止重复添加，先检查是否已存在该命令
    if ! grep -q "$HOME/jh_manager_native.sh" "$HOME/.bashrc"; then
        # \n 是为了确保命令另起一行，更规范
        echo -e "\n# 自动启动纪贺SillyTavern管理器\n$HOME/jh_manager_native.sh" >> "$HOME/.bashrc"
        echo -e "${GREEN}✔ 已成功设置“沉浸式启动”！${NC}"
    else
        echo -e "${YELLOW}检测到自动启动设置已存在，无需重复配置。${NC}"
    fi
else
    echo -e "${RED}致命错误：无法从 GitHub 下载您的 jh_manager_native.sh 脚本！${NC}"
    echo -e "${RED}安装过程无法继续，请检查网络后重试。${NC}"
    exit 1
fi
echo

# --- 安装完成，最终提示 ---
clear
echo -e "${GREEN}🎉🎉🎉 恭喜！SillyTavern 已在您的Termux中完美部署！ 🎉🎉🎉${NC}"
echo
echo -e "----------------------------------------------------"
echo -e "已为您开启了 ${YELLOW}沉浸式启动模式${NC}！"
echo
echo -e "从现在开始，您每次 ${GREEN}点击Termux应用图标${NC}，"
echo -e "就会 ${GREEN}直接进入SillyTavern管理器界面${NC}。"
echo
echo -e "如果想使用Termux命令行，只需在管理器界面按 ${RED}q${NC} 退出即可。"
echo -e "----------------------------------------------------"
echo
echo -e "\n${YELLOW}首次安装完成，正在自动进入管理器，请稍候...${NC}"
sleep 5 # 延长暂停，让用户有充足时间阅读最终提示

# 自动执行管理器，完成无缝体验的最后一环
"$HOME/jh_manager.sh"

exit 0
