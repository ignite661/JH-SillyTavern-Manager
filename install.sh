#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v5.0 - 空投绕行版)
#
# 作者: JiHe (纪贺) & AI
#
# 更新日志 (v5.0):
# - 革命性改变: 彻底绕过 apt 包管理器来安装 git。
# - git 空投: 直接下载为 arm64 编译的静态 git 二进制文件，并放置到
#   系统路径中。这能完美解决在部分设备上 apt 系统损坏导致无法安装软件的问题。
# - 流程简化: 由于不再依赖 apt 安装 git，相关检查和步骤被重构。
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
PNPM_PATH_IN_UBUNTU="/root/.local/share/pnpm/pnpm"
# 为 arm64 架构准备的静态 git 二进制文件的下载地址
STATIC_GIT_URL="https://github.com/a-lucas/git-static-arm64/releases/download/v2.33.0.1-static/git"

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

# 步骤 0: 清理旧环境
echo -e "${YELLOW}[步骤 0/8] 正在重置并清理旧的 Ubuntu 环境以确保全新安装...${NC}"
if proot-distro list | grep -q "ubuntu"; then
    proot-distro remove ubuntu -y
fi

# 步骤 1: 准备 Termux 和 Ubuntu
echo -e "${YELLOW}[步骤 1/8] 准备 Termux 环境并安装 Ubuntu...${NC}"
pkg update -y && pkg install -y proot-distro wget curl
proot-distro install ubuntu
if ! proot-distro list | grep -q "ubuntu"; then
    echo -e "${RED}致命错误: Ubuntu 安装失败！${NC}"
    exit 1
fi

# 步骤 2: 更新软件源并安装基础依赖 (不包括 git)
echo -e "${YELLOW}[步骤 2/8] 更新软件源并安装基础依赖 (python, curl)...${NC}"
# 我们仍然尝试运行 apt，但不再依赖它安装 git
run_in_ubuntu "apt-get update -y && apt-get install -y python3 curl --no-install-recommends || true"
echo -e "${GREEN}基础依赖安装尝试完成 (忽略可能的 apt 错误)。${NC}"

# 步骤 3: "空投" git (核心解决方案)
echo -e "${YELLOW}[步骤 3/8] 正在“空投” Git (绕过 apt)...${NC}"
GIT_INSTALL_CMD="wget -q '${STATIC_GIT_URL}' -O /usr/local/bin/git && chmod +x /usr/local/bin/git"
if ! run_in_ubuntu "${GIT_INSTALL_CMD}"; then
    echo -e "${RED}致命错误: Git '空投' 失败！请检查网络或 URL 是否有效。${NC}"
    exit 1
fi
# 验证 '空投' 是否成功
if ! run_in_ubuntu "command -v git &> /dev/null"; then
    echo -e "${RED}致命错误: '空投' 的 Git 未能被系统识别！安装失败。${NC}"
    exit 1
fi
echo -e "${GREEN}Git '空投' 成功并验证通过！${NC}"

# 步骤 4: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 4/8] 使用新安装的 Git 部署 SillyTavern 源码...${NC}"
if ! run_in_ubuntu "git clone ${ST_REPO_URL} ${ST_DIR_IN_UBUNTU}"; then
    echo -e "${RED}错误: git clone SillyTavern 失败！${NC}"
    exit 1
fi

# 步骤 5: 部署 Node.js
echo -e "${YELLOW}[步骤 5/8] 部署 Node.js...${NC}"
run_in_ubuntu "wget -c -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"

# 步骤 6: 创建 Node.js 全局快捷方式
echo -e "${YELLOW}[步骤 6/8] 创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"

# 步骤 7: 使用轻量级方式安装 pnpm
echo -e "${YELLOW}[步骤 7/8] 正在以轻量化方式安装 pnpm...${NC}"
if ! run_in_ubuntu "curl -fsSL https://get.pnpm.io/install.sh | sh -"; then
    echo -e "${RED}错误: pnpm 独立安装脚本执行失败！${NC}"
    exit 1
fi

# 步骤 8: 使用 pnpm 安装 SillyTavern 依赖
echo -e "${YELLOW}[步骤 8/8] 使用 pnpm 安装 SillyTavern 依赖...${NC}"
INSTALL_CMD="cd ${ST_DIR_IN_UBUNTU} && ${PNPM_PATH_IN_UBUNTU} install"
if ! run_in_ubuntu "${INSTALL_CMD}"; then
    echo -e "${RED}错误: pnpm install 失败！${NC}"
    exit 1
fi

echo -e "${GREEN}SillyTavern 依赖安装成功！正在下载配套的管理脚本...${NC}"

# 下载管理器脚本
if curl -o jh_manager.sh "${JH_MANAGER_URL}"; then
    chmod +x jh_manager.sh
    echo -e "${GREEN}\n🎉🎉🎉 恭喜！我们最终战胜了所有困难！SillyTavern 已全部安装完成！ 🎉🎉🎉${NC}"
    echo "您现在可以通过运行 './jh_manager.sh' 脚本来管理 SillyTavern。"
    echo "运行以下命令启动管理器:"
    echo -e "${YELLOW}./jh_manager.sh${NC}"
else
    echo -e "${RED}错误：无法从 GitHub 下载您的 jh_manager.sh 脚本！${NC}"
fi
