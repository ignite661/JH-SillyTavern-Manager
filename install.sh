#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v6.0.1 - 稳定修复版)
# 作者: JiHe (纪贺) & 您
# v6.0.1: 严格遵循您的稳定版逻辑，仅修复原版结尾缺失的 'fi' 语法错误。
# ==============================================================================

# --- 脚本配置 ---
# 注意：这里下载的管理器脚本需要您在 GitHub 上将其命名为 jh_manager_native.sh
JH_MANAGER_URL="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/jh_manager_native.sh"
ST_DIR_NAME="SillyTavern"
ST_REPO_URL="https://github.com/SillyTavern/SillyTavern.git"

# -- 颜色定义 --
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 安装流程 ---

# 步骤 1: 准备 Termux 原生环境 (您的方案!)
echo -e "${YELLOW}[步骤 1/5] 正在准备 Termux 原生环境...${NC}"
pkg update -y && pkg install -y git nodejs-lts curl jq

# 验证核心组件
if ! command -v git &> /dev/null || ! command -v node &> /dev/null; then
    echo -e "${RED}致命错误: git 或 nodejs-lts 未能成功安装到 Termux 环境中！${NC}"
    exit 1
fi
echo -e "${GREEN}Termux 原生环境准备就绪！Git 和 Node.js (LTS) 已安装。${NC}"
node -v # 显示 node 版本以供确认

# 步骤 2: 部署 SillyTavern 源码
echo -e "${YELLOW}[步骤 2/5] 正在将 SillyTavern 克隆到主目录...${NC}"
if [ -d "$ST_DIR_NAME" ]; then
    echo -e "${GREEN}SillyTavern 目录已存在，跳过克隆。${NC}"
else
    if ! git clone ${ST_REPO_URL} ${ST_DIR_NAME}; then
        echo -e "${RED}错误: git clone SillyTavern 失败！请检查网络。${NC}"
        exit 1
    fi
fi

# 步骤 3: 安装 pnpm
echo -e "${YELLOW}[步骤 3/5] 正在全局安装 pnpm...${NC}"
if ! npm i -g pnpm; then
    echo -e "${RED}错误: pnpm 安装失败！${NC}"
    exit 1
fi

# 步骤 4: 安装 SillyTavern 依赖
echo -e "${YELLOW}[步骤 4/5] 进入 SillyTavern 目录并使用 pnpm 安装依赖...${NC}"
cd ${ST_DIR_NAME}
if ! pnpm install; then
    echo -e "${RED}错误: pnpm install 失败！${NC}"
    exit 1
fi
cd .. # 返回主目录

# 步骤 5: 下载配套的管理脚本
echo -e "${YELLOW}[步骤 5/5] 正在下载配套的原生管理脚本...${NC}"
# 注意：这里我们下载后统一命名为 jh_manager.sh，方便用户使用
if curl -o jh_manager.sh "${JH_MANAGER_URL}"; then
    chmod +x jh_manager.sh
    echo -e "${GREEN}\n🎉🎉🎉 最终的胜利！SillyTavern 已在原生 Termux 环境中完美部署！ 🎉🎉🎉${NC}"
    echo "您现在可以通过运行 './jh_manager.sh' 脚本来管理 SillyTavern。"
    echo "运行以下命令启动管理器:"
    echo -e "${YELLOW}./jh_manager.sh${NC}"
else
    echo -e "${RED}错误：无法从 GitHub 下载您的 jh_manager.sh 脚本！${NC}"
fi # <--- 这是唯一的、必须的补充，用来修复语法错误
