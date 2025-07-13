#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v3.0 - 自愈健壮版)
#
# 作者: JiHe (纪贺) & AI
#
# 更新日志 (v3.0):
# - 鲁棒性增强: 新增【环境自检与修复模块】，可自动修复常见的 Termux
#   'dpkg interrupted' 错误，实现真正的开箱即用一键安装。
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

# ==============================================================================
# [新增模块] 步骤 0: 环境自检与修复
# ==============================================================================
echo -e "${YELLOW}[步骤 0/8] 正在进行 Termux 环境自检与修复...${NC}"
# 这一步是关键！主动修复可能存在的 dpkg 中断问题。
# 对于健康系统，此命令无任何副作用。
dpkg --configure -a > /dev/null 2>&1
echo -e "${GREEN}环境自检完成。${NC}"


echo -e "${YELLOW}[步骤 1/8] 准备 Termux 基础环境...${NC}"
# 首先更新包列表，然后才安装依赖
pkg update -y
# 现在再安装我们的核心依赖，成功率大大提高！
pkg install -y proot-distro git wget curl
if ! command -v proot-distro &> /dev/null; then
    echo -e "${RED}致命错误: proot-distro 安装失败！请检查您的 Termux 或网络环境。${NC}"
    exit 1
fi

echo -e "${YELLOW}[步骤 2/8] 安装 Ubuntu 22.04...${NC}"
if ! proot-distro list | grep -q "ubuntu"; then
    proot-distro install ubuntu
fi

echo -e "${YELLOW}[步骤 3/8] 更新 Ubuntu 内部环境...${NC}"
run_in_ubuntu "apt-get update && apt-get upgrade -y && apt-get install -y build-essential python3"

echo -e "${YELLOW}[步骤 4/8] 部署 SillyTavern 源码...${NC}"
UBUNTU_ROOTFS_PATH=$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu
if [ ! -d "${UBUNTU_ROOTFS_PATH}${ST_DIR_IN_UBUNTU}" ]; then
    # 使用 git clone 到 Termux 的临时目录，然后移动到 Ubuntu 内部
    git clone ${ST_REPO_URL} /tmp/${ST_DIR_NAME}
    if [ -d "/tmp/${ST_DIR_NAME}" ]; then
        mv /tmp/${ST_DIR_NAME} "${UBUNTU_ROOTFS_PATH}${ST_DIR_IN_UBUNTU}"
    else
        echo -e "${RED}错误: git clone SillyTavern 失败！请检查网络或 GitHub 访问。${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}[步骤 5/8] 部署 Node.js...${NC}"
run_in_ubuntu "wget -c -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"

echo -e "${YELLOW}[步骤 6/8] 创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npx /usr/local/bin/npx"

echo -e "${YELLOW}[步骤 7/8] 安装内存优化工具 pnpm...${NC}"
run_in_ubuntu "npm install -g pnpm"

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

