#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v5.1 - 智能适应版)
#
# 作者: JiHe (纪贺) & AI
#
# 更新日志 (v5.1):
# - 智能环境适应: 彻底改变安装逻辑。不再强制删除和重装 Ubuntu。
# - 检查与决策: 脚本现在会先检查 Ubuntu 是否已存在。如果存在，则直接
#   使用现有环境并跳过安装；如果不存在，才执行全新安装。
# - 终极健壮性: 这种新逻辑完美解决了因无法删除旧环境而导致的安装失败问题。
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

# 步骤 1: 准备 Termux 和 Ubuntu (智能适应逻辑)
echo -e "${YELLOW}[步骤 1/8] 准备 Termux 环境并检查 Ubuntu...${NC}"
pkg update -y && pkg install -y proot-distro wget curl

if proot-distro list | grep -q "ubuntu"; then
    echo -e "${GREEN}检测到 Ubuntu 已存在，将直接使用现有环境，跳过安装步骤。${NC}"
else
    echo -e "${YELLOW}未检测到 Ubuntu, 正在进行全新安装...${NC}"
    if ! proot-distro install ubuntu; then
        echo -e "${RED}致命错误: Ubuntu 全新安装失败！请检查网络或存储空间。${NC}"
        exit 1
    fi
    echo -e "${GREEN}Ubuntu 全新安装成功。${NC}"
fi

# 步骤 2: 更新软件源并安装基础依赖 (不包括 git)
echo -e "${YELLOW}[步骤 2/8] 更新软件源并安装基础依赖 (python, curl)...${NC}"
run_in_ubuntu "apt-get update -y && apt-get install -y python3 curl --no-install-recommends || true"
echo -e "${GREEN}基础依赖安装尝试完成 (忽略可能的 apt 错误)。${NC}"

# 步骤 3: "空投" git (核心解决方案)
echo -e "${YELLOW}[步骤 3/8] 正在“空投” Git (绕过 apt)...${NC}"
GIT_INSTALL_CMD="wget -q '${STATIC_GIT_URL}' -O /usr/local/bin/git && chmod +x /usr/local/bin/git"
if ! run_in_ubuntu "${GIT_INSTALL_CMD}"; then
    echo -e "${RED}致命错误: Git '空投' 失败！${NC}"
    exit 1
fi
if ! run_in_ubuntu "command -v git &> /dev/null"; then
    echo -e "${RED}致命错误: '空投' 的 Git 未能被系统识别！${NC}"
    exit 1
fi
echo -e "${GREEN}Git '空投' 成功并验证通过！${NC}"

# 步骤 4: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 4/8] 使用 Git 部署 SillyTavern 源码...${NC}"
# 如果目录已存在，则不进行 clone，防止出错
if ! run_in_ubuntu "[ -d '${ST_DIR_IN_UBUNTU}' ]"; then
    if ! run_in_ubuntu "git clone ${ST_REPO_URL} ${ST_DIR_IN_UBUNTU}"; then
        echo -e "${RED}错误: git clone SillyTavern 失败！${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}SillyTavern 目录已存在，跳过 clone。${NC}"
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
