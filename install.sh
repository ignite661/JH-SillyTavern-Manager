#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v3.1 - 核心逻辑优化版)
#
# 作者: JiHe (纪贺) & AI
#
# 更新日志 (v3.1):
# - 核心逻辑重构: 将 git clone 操作移至 Ubuntu 内部执行，彻底解决
#   在部分设备上 Termux 的 /tmp 目录出现 'Read-only file system' 的问题。
#   这使得安装流程更加原子化和可靠。
# - 依赖内化: 在 Ubuntu 环境中直接安装 git，减少对外部环境的依赖。
# ==============================================================================

# ==============================================================================
# ！！！您的个人配置区域，请勿修改！！！
# ==============================================================================
JH_MANAGER_URL="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/jh_manager.sh"


# -- 脚本内部配置 --
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"
NODE_VERSION="v20.12.2"
NODE_PKG_NAME="node-${NODE_VERSION}-linux-arm64"
NODE_DOWNLOAD_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_PKG_NAME}.tar.xz"
ST_DIR_IN_UBUNTU="/root/${ST_DIR_NAME}"
NODE_PATH_IN_UBUNTU="/root/${NODE_PKG_NAME}/bin"

# -- 颜色定义 --
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 辅助函数 ---
run_in_ubuntu() {
    proot-distro login ubuntu --shared-tmp --user root -- bash -c "$1"
}

# --- 安装流程 ---

# 步骤 0: 环境自检与修复
echo -e "${YELLOW}[步骤 0/8] 正在进行 Termux 环境自检与修复...${NC}"
dpkg --configure -a > /dev/null 2>&1
echo -e "${GREEN}环境自检完成。${NC}"


# 步骤 1: 准备 Termux 基础环境
echo -e "${YELLOW}[步骤 1/8] 准备 Termux 基础环境...${NC}"
pkg update -y
pkg install -y proot-distro wget curl
if ! command -v proot-distro &> /dev/null; then
    echo -e "${RED}致命错误: proot-distro 安装失败！请检查您的 Termux 或网络环境。${NC}"
    exit 1
fi

# 步骤 2: 安装 Ubuntu 22.04
echo -e "${YELLOW}[步骤 2/8] 安装 Ubuntu 22.04...${NC}"
if ! proot-distro list | grep -q "ubuntu"; then
    proot-distro install ubuntu
fi

# 步骤 3: 更新 Ubuntu 内部环境 (核心改动点)
echo -e "${YELLOW}[步骤 3/8] 更新 Ubuntu 内部环境并安装核心依赖...${NC}"
# 在这里，我们把 git 也一起安装到 Ubuntu 内部
run_in_ubuntu "apt-get update && apt-get upgrade -y && apt-get install -y build-essential python3 git"

# 步骤 4: 部署 SillyTavern 源码 (核心改动点)
echo -e "${YELLOW}[步骤 4/8] 部署 SillyTavern 源码...${NC}"
# 我们直接在 Ubuntu 内部进行 clone，不再使用外部 /tmp
if ! run_in_ubuntu "[ -d '${ST_DIR_IN_UBUNTU}' ]"; then
    echo "正在从 GitHub 克隆 SillyTavern..."
    if ! run_in_ubuntu "git clone ${ST_REPO_URL} ${ST_DIR_IN_UBUNTU}"; then
        echo -e "${RED}错误: git clone SillyTavern 失败！请检查上方具体的 git 错误信息。${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}SillyTavern 源码部署成功。${NC}"

# 步骤 5: 部署 Node.js
echo -e "${YELLOW}[步骤 5/8] 部署 Node.js...${NC}"
run_in_ubuntu "wget -c -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"

# 步骤 6: 创建 Node.js 全局快捷方式
echo -e "${YELLOW}[步骤 6/8] 创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npx /usr/local/bin/npx"

# 步骤 7: 安装内存优化工具 pnpm
echo -e "${YELLOW}[步骤 7/8] 安装内存优化工具 pnpm...${NC}"
run_in_ubuntu "npm install -g pnpm"

# 步骤 8: 使用 pnpm 安装 SillyTavern 依赖
echo -e "${YELLOW}[步骤 8/8] 使用 pnpm 安装 SillyTavern 依赖...${NC}"
INSTALL_CMD="cd ${ST_DIR_IN_UBUNTU} && pnpm install"
if ! run_in_ubuntu "${INSTALL_CMD}"; then
    echo -e "${RED}错误: pnpm install 失败！请截图反馈。${NC}"
    exit 1
fi

echo -e "${GREEN}SillyTavern 依赖安装成功！正在下载配套的管理脚本...${NC}"

# 从您的 GitHub 仓库下载管理器脚本
if curl -o jh_manager.sh "${JH_MANAGER_URL}"; then
    chmod +x jh_manager.sh
    echo -e "${GREEN}\n🎉🎉🎉 恭喜！SillyTavern 已全部安装完成！ 🎉🎉🎉${NC}"
    echo "您现在可以通过运行 './jh_manager.sh' 脚本来管理 SillyTavern。"
    echo "运行以下命令启动管理器:"
    echo -e "${YELLOW}./jh_manager.sh${NC}"
else
    echo -e "${RED}错误：无法从 GitHub 下载您的 jh_manager.sh 脚本！${NC}"
    echo -e "${RED}请检查 install.sh 顶部的 JH_MANAGER_URL 是否正确！${NC}"
fi

