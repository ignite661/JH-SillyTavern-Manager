#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v9.0 - 经典回归版)
#
# 作者: JiHe (纪贺)
#
# 更新日志 (v9.0):
# - 经典回归: 采纳您的核心思想，回归至最稳定可靠的“安装器+管理器”双文件架构。
# - 依赖优化: 使用 Termux 包管理器直接安装 pnpm，取代 npm 全局安装，更稳定高效。
# - 细节修复: 修复了 v6.0 版本中的 fi 语法错误，并美化了输出。
# ==============================================================================

# --- 配置 ---
JH_MANAGER_URL="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/jh_manager.sh"
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

# --- 欢迎信息 ---
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo -e "${C_WHITE}  SillyTavern Termux 一键安装脚本 (经典回归版)    ${C_RESET}"
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo
read -p "按 Enter 键开始安装，按 Ctrl+C 中止..."

# --- 步骤 1: 安装核心依赖 ---
echo -e "\n${C_YELLOW}>>> [1/4] 正在更新软件包并安装核心依赖 (Git, Node.js, pnpm)...${C_RESET}"
# 关键修复：使用 --force-confnew 选项避免因配置文件冲突而暂停
# 关键优化：直接使用 pkg 安装 pnpm
pkg update -y && pkg upgrade -o Dpkg::Options::="--force-confnew" -y
pkg install git nodejs-lts pnpm curl -y

# 验证
if ! command -v node &> /dev/null || ! command -v pnpm &> /dev/null; then
    echo -e "\n${C_RED}致命错误: Node.js 或 pnpm 未能成功安装！脚本中止。${C_RESET}"
    exit 1
fi
echo -e "${C_GREEN}✓ 核心依赖安装成功！${C_RESET}"
echo -n "  Node.js 版本: "; node -v
echo -n "  pnpm 版本: "; pnpm -v

# --- 步骤 2: 克隆 SillyTavern 仓库 ---
echo -e "\n${C_YELLOW}>>> [2/4] 正在从 GitHub 克隆 SillyTavern...${C_RESET}"
if [ -d "$ST_DIR_NAME" ]; then
    echo "  检测到已存在的 SillyTavern 目录，跳过克隆。"
else
    if ! git clone ${ST_REPO_URL} ${ST_DIR_NAME}; then
        echo -e "\n${C_RED}错误: 克隆 SillyTavern 失败！请检查您的网络连接。${C_RESET}"
        exit 1
    fi
fi
echo -e "${C_GREEN}✓ SillyTavern 克隆完成！${C_RESET}"

# --- 步骤 3: 安装项目依赖 ---
echo -e "\n${C_YELLOW}>>> [3/4] 正在安装项目依赖，这可能需要几分钟...${C_RESET}"
cd ${ST_DIR_NAME}
if ! pnpm install; then
    echo -e "\n${C_RED}错误: 'pnpm install' 执行失败！${C_RESET}"
    exit 1
fi
cd .. # 返回主目录
echo -e "${C_GREEN}✓ 项目依赖安装成功！${C_RESET}"

# --- 步骤 4: 下载您的专属管理器 ---
echo -e "\n${C_YELLOW}>>> [4/4] 正在下载您设计的专属管理器 (jh_manager.sh)...${C_RESET}"
if curl -L -o jh_manager.sh "${JH_MANAGER_URL}"; then
    chmod +x jh_manager.sh
    echo -e "${C_GREEN}✓ 管理器下载成功！${C_RESET}"
    echo
    echo -e "${C_CYAN}=====================================================${C_RESET}"
    echo -e "${C_GREEN}    🎉🎉🎉 恭喜！SillyTavern 已全部安装完成！ 🎉🎉🎉    ${C_RESET}"
    echo -e "${C_CYAN}=====================================================${C_RESET}"
    echo
    echo -e "现在，请使用我们为您定制的专属管理器来操作："
    echo -e "  1. 在命令行输入 ${C_YELLOW}./jh_manager.sh${C_RESET}"
    echo -e "  2. 在弹出的菜单中选择 ${C_GREEN}'1'${C_RESET} 即可启动！"
    echo
else
    echo -e "${C_RED}致命错误: 无法从 GitHub 下载管理器脚本！请检查网络或 URL。${C_RESET}"
fi
