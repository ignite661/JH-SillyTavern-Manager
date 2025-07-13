#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v2.7 - 符号链接终极版)
#
# 更新日志 (v2.7):
# - 核心变更: 在安装 Node.js 后，为其可执行文件 (node, npm, npx) 在
#   /usr/local/bin 中创建符号链接 (symlink)。
# - 目的: 彻底解决在某些特殊安卓系统上 PATH 环境变量无法正确传递到
#   proot 容器内的问题。通过符号链接，让 node 和 npm 成为全局可用的命令，
#   任何脚本（包括 npm 自身）都能找到它们，不再依赖 PATH。
# - 这被认为是解决此顽固问题的最终、最标准、最可靠的方法。
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
# 在 Ubuntu 容器中以 root 身份执行命令
run_in_ubuntu() {
    proot-distro login ubuntu --shared-tmp --user root -- bash -c "$1"
}

# --- 安装流程 ---

# 步骤 1: Termux 基础环境准备
echo -e "${YELLOW}[步骤 1/6] 准备 Termux 环境...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y proot-distro git wget curl
echo -e "${GREEN}Termux 环境准备就绪。${NC}"

# 步骤 2: 安装和配置 Ubuntu
echo -e "${YELLOW}[步骤 2/6] 安装 Ubuntu 22.04 (如果未安装)...${NC}"
if ! proot-distro list | grep -q "ubuntu"; then
    proot-distro install ubuntu
else
    echo "Ubuntu 已安装，跳过。"
fi
# 更新 Ubuntu 内部的包
echo "正在更新 Ubuntu 内部软件包..."
run_in_ubuntu "apt-get update && apt-get upgrade -y"
echo -e "${GREEN}Ubuntu 安装和更新完成。${NC}"

# 步骤 3: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 3/6] 正在部署 SillyTavern 源码...${NC}"
# 注意：我们直接在 Termux 环境下操作 proot 的文件系统，更稳定
UBUNTU_ROOTFS_PATH=$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu
if [ -d "${UBUNTU_ROOTFS_PATH}${ST_DIR_IN_UBUNTU}" ]; then
    echo "SillyTavern 目录已存在，跳过克隆。"
else
    # 在 Termux 中克隆到临时位置，然后移动进去
    git clone ${ST_REPO_URL} /tmp/${ST_DIR_NAME}
    mv /tmp/${ST_DIR_NAME} "${UBUNTU_ROOTFS_PATH}${ST_DIR_IN_UBUNTU}"
fi
echo -e "${GREEN}SillyTavern 源码部署成功。${NC}"

# 步骤 4: 部署预编译的 Node.js
echo -e "${YELLOW}[步骤 4/6] 正在部署 Node.js...${NC}"
if run_in_ubuntu "[ ! -f /root/${NODE_PKG_NAME}.tar.xz ]"; then
    run_in_ubuntu "wget -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
fi
if run_in_ubuntu "[ ! -d ${NODE_PATH_IN_UBUNTU} ]"; then
    run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"
fi
echo -e "${GREEN}Node.js 文件部署成功。${NC}"

# =================================================================
# 步骤 4.5: 创建符号链接 (终极解决方案)
# =================================================================
echo -e "${YELLOW}[步骤 4.5/6] 正在创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npx /usr/local/bin/npx"
echo -e "${GREEN}Node.js 全局快捷方式创建成功！${NC}"

# 步骤 5: 安装 SillyTavern 依赖
echo -e "${YELLOW}[步骤 5/6] 正在安装 SillyTavern 依赖 (终极模式)...${NC}"
echo "这一步耗时最长，请保持耐心"
# 现在，因为有了符号链接，我们可以直接调用 npm，它会自己找到 node
INSTALL_CMD="cd ${ST_DIR_IN_UBUNTU} && npm install"
if run_in_ubuntu "${INSTALL_CMD}"; then
    echo -e "${GREEN}SillyTavern 依赖安装成功！${NC}"
else
    echo -e "${RED}错误: npm install 失败！请截图反馈。${NC}"
    exit 1
fi

# 步骤 6: 完成和后续指示
echo -e "${YELLOW}[步骤 6/6] 安装完成！正在创建管理脚本...${NC}"

echo -e "${GREEN}\n🎉🎉🎉 恭喜！SillyTavern 已全部安装完成！ 🎉🎉🎉${NC}"
echo "您现在可以通过运行 './jh_manager.sh' 脚本来管理 SillyTavern。"
echo "运行以下命令启动管理器:"
echo -e "${YELLOW}./jh_manager.sh${NC}"

