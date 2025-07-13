#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v2.8 - pnpm 融合版)
#
# 更新日志 (v2.8):
# - 核心优化: 融合社区最佳实践，引入 pnpm 作为首选包管理器。
# - 目的: pnpm 能显著降低内存占用，避免在低配设备上因内存不足(Killed)
#   导致的安装失败，同时安装速度更快，硬盘占用更少。
# - 步骤调整: 在 Node.js 链接创建后，增加一步全局安装 pnpm。
# ==============================================================================

# -- 配置 --
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"
NODE_VERSION="v20.12.2"
NODE_PKG_NAME="node-${NODE_VERSION}-linux-arm64"
NODE_DOWNLOAD_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_PKG_NAME}.tar.xz"

# Ubuntu 内部路径定义
ST_DIR_IN_UBUNTU="/root/${ST_DIR_NAME}"
NODE_PATH_IN_UBUNTU="/root/${NODE_PKG_NAME}/bin"

# -- 颜色定义 --
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- 辅助函数 ---
run_in_ubuntu() {
    proot-distro login ubuntu --shared-tmp --user root -- bash -c "$1"
}

# --- 安装流程 ---

# 步骤 1: Termux 基础环境准备
echo -e "${YELLOW}[步骤 1/7] 准备 Termux 环境...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y proot-distro git wget curl
echo -e "${GREEN}Termux 环境准备就绪。${NC}"

# 步骤 2: 安装和配置 Ubuntu
echo -e "${YELLOW}[步骤 2/7] 安装 Ubuntu 22.04 (如果未安装)...${NC}"
if ! proot-distro list | grep -q "ubuntu"; then
    proot-distro install ubuntu
else
    echo "Ubuntu 已安装，跳过。"
fi
echo "正在更新 Ubuntu 内部软件包..."
run_in_ubuntu "apt-get update && apt-get upgrade -y && apt-get install -y build-essential python3"
echo -e "${GREEN}Ubuntu 安装和更新完成。${NC}"

# 步骤 3: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 3/7] 正在部署 SillyTavern 源码...${NC}"
UBUNTU_ROOTFS_PATH=$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu
if [ -d "${UBUNTU_ROOTFS_PATH}${ST_DIR_IN_UBUNTU}" ]; then
    echo "SillyTavern 目录已存在，跳过克隆。"
else
    git clone ${ST_REPO_URL} /tmp/${ST_DIR_NAME}
    mv /tmp/${ST_DIR_NAME} "${UBUNTU_ROOTFS_PATH}${ST_DIR_IN_UBUNTU}"
fi
echo -e "${GREEN}SillyTavern 源码部署成功。${NC}"

# 步骤 4: 部署预编译的 Node.js
echo -e "${YELLOW}[步骤 4/7] 正在部署 Node.js...${NC}"
if run_in_ubuntu "[ ! -f /root/${NODE_PKG_NAME}.tar.xz ]"; then
    run_in_ubuntu "wget -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
fi
if run_in_ubuntu "[ ! -d ${NODE_PATH_IN_UBUNTU} ]"; then
    run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"
fi
echo -e "${GREEN}Node.js 文件部署成功。${NC}"

# 步骤 5: 创建符号链接 (终极解决方案)
echo -e "${YELLOW}[步骤 5/7] 正在创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npx /usr/local/bin/npx"
echo -e "${GREEN}Node.js 全局快捷方式创建成功！${NC}"

# =================================================================
# 步骤 6: 安装终极武器 pnpm (新增的关键步骤)
# =================================================================
echo -e "${YELLOW}[步骤 6/7] 正在安装内存优化工具 pnpm...${NC}"
run_in_ubuntu "npm install -g pnpm"
echo -e "${GREEN}pnpm 安装成功！我们将使用它来安装依赖。${NC}"

# 步骤 7: 使用 pnpm 安装 SillyTavern 依赖
echo -e "${YELLOW}[步骤 7/7] 正在安装 SillyTavern 依赖 (pnpm 高效模式)...${NC}"
echo "这一步耗时会比 npm 大幅缩短，请保持耐心"
# 使用 pnpm 代替 npm，解决内存问题
INSTALL_CMD="cd ${ST_DIR_IN_UBUNTU} && pnpm install"
if run_in_ubuntu "${INSTALL_CMD}"; then
    echo -e "${GREEN}SillyTavern 依赖安装成功！${NC}"
else
    echo -e "${RED}错误: pnpm install 失败！请截图反馈。${NC}"
    exit 1
fi

# 完成和后续指示
echo -e "${GREEN}\n🎉🎉🎉 恭喜！SillyTavern 已全部安装完成！ 🎉🎉🎉${NC}"
echo "管理脚本 'jh_manager.sh' 也已准备就绪。"
echo "请运行以下命令启动管理器:"
echo -e "${YELLOW}./jh_manager.sh${NC}"

