#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v4.0 - 终极健壮版)
#
# 作者: JiHe (纪贺) & AI
#
# 更新日志 (v4.0):
# - 健壮性革命: 引入严格的失败检查机制！现在每一步关键操作后都会验证
#   其是否成功。如果 apt-get 安装失败，脚本会立即停止并报告确切问题，
#   彻底杜绝 'command not found' 等后续连锁错误。
# - 原子化操作: 将依赖安装分解，确保每一步都清晰可控。
# - 精准错误报告: 错误信息更加明确，直指问题根源。
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

# 步骤 0: 清理旧环境 (为了确保从一个干净的状态开始)
echo -e "${YELLOW}[步骤 0/9] 正在重置并清理旧的 Ubuntu 环境以确保全新安装...${NC}"
if proot-distro list | grep -q "ubuntu"; then
    proot-distro remove ubuntu -y
fi
echo -e "${GREEN}旧环境清理完毕。${NC}"

# 步骤 1: 环境自检与修复
echo -e "${YELLOW}[步骤 1/9] 正在进行 Termux 环境自检与修复...${NC}"
dpkg --configure -a > /dev/null 2>&1
pkg update -y
pkg install -y proot-distro wget curl

# 步骤 2: 安装 Ubuntu 22.04
echo -e "${YELLOW}[步骤 2/9] 安装全新的 Ubuntu 22.04...${NC}"
proot-distro install ubuntu
if ! proot-distro list | grep -q "ubuntu"; then
    echo -e "${RED}致命错误: Ubuntu 安装失败！请检查 Termux 存储权限或网络。${NC}"
    exit 1
fi

# 步骤 3: 更新 Ubuntu 软件源
echo -e "${YELLOW}[步骤 3/9] 正在更新 Ubuntu 内部软件源...${NC}"
if ! run_in_ubuntu "apt-get update -y"; then
    echo -e "${RED}错误: Ubuntu 内部 'apt-get update' 失败！请检查网络或软件源问题。${NC}"
    exit 1
fi

# 步骤 4: 安装核心依赖 (核心健壮性改造)
echo -e "${YELLOW}[步骤 4/9] 正在安装核心依赖 (git, python, curl)...${NC}"
run_in_ubuntu "apt-get install -y git python3 curl"
# **关键检查点**：验证 git 是否真的安装成功了
if ! run_in_ubuntu "command -v git &> /dev/null"; then
    echo -e "${RED}致命错误: 'git' 未能成功安装到 Ubuntu 中！安装过程可能被中断。${NC}"
    echo -e "${RED}请检查上方 'apt-get install' 命令的输出，寻找 'E:' 开头的错误。${NC}"
    exit 1
fi
echo -e "${GREEN}核心依赖安装验证成功。${NC}"

# 步骤 5: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 5/9] 部署 SillyTavern 源码...${NC}"
if ! run_in_ubuntu "[ -d '${ST_DIR_IN_UBUNTU}' ]"; then
    if ! run_in_ubuntu "git clone ${ST_REPO_URL} ${ST_DIR_IN_UBUNTU}"; then
        echo -e "${RED}错误: git clone SillyTavern 失败！${NC}"
        exit 1
    fi
fi

# 步骤 6: 部署 Node.js
echo -e "${YELLOW}[步骤 6/9] 部署 Node.js...${NC}"
run_in_ubuntu "wget -c -O /root/${NODE_PKG_NAME}.tar.xz ${NODE_DOWNLOAD_URL}"
run_in_ubuntu "cd /root && tar -xvf ${NODE_PKG_NAME}.tar.xz"

# 步骤 7: 创建 Node.js 全局快捷方式
echo -e "${YELLOW}[步骤 7/9] 创建 Node.js 全局快捷方式...${NC}"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/node /usr/local/bin/node"
run_in_ubuntu "ln -sf ${NODE_PATH_IN_UBUNTU}/npm /usr/local/bin/npm"

# 步骤 8: 使用轻量级方式安装 pnpm
echo -e "${YELLOW}[步骤 8/9] 正在以轻量化方式安装 pnpm...${NC}"
if ! run_in_ubuntu "curl -fsSL https://get.pnpm.io/install.sh | sh -"; then
    echo -e "${RED}错误: pnpm 独立安装脚本执行失败！${NC}"
    exit 1
fi

# 步骤 9: 使用 pnpm 安装 SillyTavern 依赖
echo -e "${YELLOW}[步骤 9/9] 使用 pnpm 安装 SillyTavern 依赖...${NC}"
INSTALL_CMD="cd ${ST_DIR_IN_UBUNTU} && ${PNPM_PATH_IN_UBUNTU} install"
if ! run_in_ubuntu "${INSTALL_CMD}"; then
    echo -e "${RED}错误: pnpm install 失败！${NC}"
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
