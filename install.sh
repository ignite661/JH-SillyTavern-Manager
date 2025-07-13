#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v3.2 - 性能优化终极版)
#
# 作者: JiHe (纪贺) & AI
#
# 更新日志 (v3.2):
# - 性能优化: 彻底废除使用 "npm install -g pnpm" 的方式。
# - 全新安装方式: 采用 pnpm 官方推荐的独立安装脚本来安装 pnpm，
#   该方法轻量、快速，完美绕过 npm 导致的内存和 I/O 性能瓶颈。
# - 路径修正: 精准定位 pnpm 的安装路径，确保后续命令能正确调用。
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
PNPM_PATH_IN_UBUNTU="/root/.local/share/pnpm/pnpm" # pnpm 的标准安装路径

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
    echo -e "${RED}致命错误: proot-distro 安装失败！${NC}"
    exit 1
fi

# 步骤 2: 安装 Ubuntu 22.04
echo -e "${YELLOW}[步骤 2/8] 安装 Ubuntu 22.04...${NC}"
if ! proot-distro list | grep -q "ubuntu"; then
    proot-distro install ubuntu
fi

# 步骤 3: 更新 Ubuntu 内部环境
echo -e "${YELLOW}[步骤 3/8] 更新 Ubuntu 内部环境并安装核心依赖...${NC}"
run_in_ubuntu "apt-get update && apt-get upgrade -y && apt-get install -y build-essential python3 git curl"

# 步骤 4: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 4/8] 部署 SillyTavern 源码...${NC}"
if ! run_in_ubuntu "[ -d '${ST_DIR_IN_UBUNTU}' ]"; then
    if ! run_in_ubuntu "git clone ${ST_REPO_URL} ${ST_DIR_IN_UBUNTU}"; then
        echo -e "${RED}错误: git clone SillyTavern 失败！${NC}"
        exit 1
    fi
fi

# 步骤 5: 部署 Node.js
echo -e "${YELLOW}[步骤 5/8] 部署 Node.js...${NC}"
run_in_ubuntu "wget -c -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"

# 步骤 6: 创建 Node.js 全局快捷方式
echo -e "${YELLOW}[步骤 6/8] 创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npx /usr/local/bin/npx"

# 步骤 7: 使用轻量级方式安装 pnpm (核心优化点)
echo -e "${YELLOW}[步骤 7/8] 正在以轻量化方式安装 pnpm... (绕过 npm 瓶颈)${NC}"
# 使用 pnpm 官方推荐的独立安装脚本，这不会触发内存风暴
if ! run_in_ubuntu "curl -fsSL https://get.pnpm.io/install.sh | sh -"; then
    echo -e "${RED}错误: pnpm 独立安装脚本执行失败！请截图反馈。${NC}"
    exit 1
fi

# 步骤 8: 使用 pnpm 安装 SillyTavern 依赖 (核心优化点)
echo -e "${YELLOW}[步骤 8/8] 使用 pnpm 安装 SillyTavern 依赖...${NC}"
# 使用 pnpm 的绝对路径来执行安装，确保找到命令
INSTALL_CMD="cd ${ST_DIR_IN_UBUNTU} && ${PNPM_PATH_IN_UBUNTU} install"
if ! run_in_ubuntu "${INSTALL_CMD}"; then
    echo -e "${RED}错误: pnpm install 失败！请截图反馈。${NC}"
    exit 1
fi

echo -e "${GREEN}SillyTavern 依赖安装成功！正在下载配套的管理脚本...${NC}"

# 下载管理器脚本
if curl -o jh_manager.sh "${JH_MANAGER_URL}"; then
    chmod +x jh_manager.sh
    echo -e "${GREEN}\n🎉🎉🎉 恭喜！SillyTavern 已全部安装完成！ 🎉🎉🎉${NC}"
    echo "您现在可以通过运行 './jh_manager.sh' 脚本来管理 SillyTavern。"
    echo "运行以下命令启动管理器:"
    echo -e "${YELLOW}./jh_manager.sh${NC}"
else
    echo -e "${RED}错误：无法从 GitHub 下载您的 jh_manager.sh 脚本！${NC}"
fi
