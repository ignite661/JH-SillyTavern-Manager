#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键部署脚本 (JH-Installer v2.1)
#
# 作者: 纪贺科技 (ignite661)
# 仓库: https://github.com/ignite661/JH-SillyTavern-Manager
#
# 此脚本为一键化设计，通过 'curl | bash' 执行。
# 它采用绕行策略以避免 'apt' 挂起问题，并会自动下载配套的管理脚本。
# ==============================================================================

# --- 配置 ---
# GitHub 用户名和仓库名
GH_USER="ignite661"
GH_REPO="JH-SillyTavern-Manager"
# Node.js 版本和目录
NODE_VERSION="v20.12.2"
NODE_DIR_NAME="node-${NODE_VERSION}-linux-arm64"
NODE_ARCHIVE="${NODE_DIR_NAME}.tar.xz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_ARCHIVE}"
# 管理脚本名称
MANAGER_SCRIPT="jh_manager.sh"

# --- 函数定义 ---
# 打印带颜色的消息
print_step() {
    echo -e "\n\033[1;34m[步骤 $1] $2\033[0m"
}

print_success() {
    echo -e "\033[0;32m$1\033[0m"
}

print_error() {
    echo -e "\033[0;31m错误: $1\033[0m"
    exit 1
}

# --- 主程序开始 ---
clear
echo "欢迎使用纪贺科技 SillyTavern 一键部署脚本"
echo "--------------------------------------------------------"
echo "此脚本将全自动完成部署，请确保网络连接稳定。"
echo "部署过程可能需要 10-20 分钟，请耐心等待..."
sleep 4

# 步骤 1: 准备 Termux 环境
print_step "1/6" "正在更新并准备 Termux 环境..."
pkg update -y && pkg upgrade -y
pkg install proot-distro git curl -y || print_error "Termux 基础包安装失败。"
print_success "Termux 环境准备完毕。"

# 步骤 2: 清理并安装 Ubuntu
print_step "2/6" "正在安装 Ubuntu 容器..."
# 彻底移除旧环境，确保干净
proot-distro remove ubuntu &>/dev/null
proot-distro install ubuntu || print_error "Ubuntu 安装失败！请检查网络或 Termux 权限。"
ubuntu_root=$(proot-distro path ubuntu)
if [ ! -d "$ubuntu_root" ]; then
   print_error "未能找到 Ubuntu 安装路径。"
fi
print_success "Ubuntu 容器安装成功。"

# 步骤 3: 部署 SillyTavern 源码
print_step "3/6" "正在部署 SillyTavern..."
if [ -d "$ubuntu_root/root/SillyTavern" ]; then
    rm -rf "$ubuntu_root/root/SillyTavern"
fi
git clone https://github.com/SillyTavern/SillyTavern.git "$ubuntu_root/root/SillyTavern" || print_error "SillyTavern 克隆失败！请检查网络和 git 是否正常。"
print_success "SillyTavern 源码部署成功。"

# 步骤 4: 在 Ubuntu 中部署 Node.js
print_step "4/6" "正在 Ubuntu 中部署 Node.js (预编译版)..."
proot-distro login ubuntu --shared-tmp -- bash -c " \
    cd /root && \
    echo '  -> 正在下载 Node.js...' && \
    curl -L -o ${NODE_ARCHIVE} ${NODE_URL} && \
    echo '  -> 正在解压...' && \
    tar -xf ${NODE_ARCHIVE} && \
    rm ${NODE_ARCHIVE} && \
    echo '  -> 正在配置环境变量...' && \
    echo 'export PATH=/root/${NODE_DIR_NAME}/bin:\$PATH' >> /root/.bashrc \
"
# 验证 Node.js 是否安装成功
NODE_CHECK=$(proot-distro login ubuntu --shared-tmp -- bash -c "source /root/.bashrc && command -v node")
if [ -z "$NODE_CHECK" ]; then
    print_error "Node.js 部署失败！"
fi
print_success "Node.js 部署成功。"

# 步骤 5: 安装 SillyTavern 依赖
print_step "5/6" "正在安装 SillyTavern 依赖 (npm install)..."
echo "这一步耗时最长，请保持耐心，不要锁屏！"
proot-distro login ubuntu --shared-tmp -- bash -c " \
    source /root/.bashrc && \
    cd /root/SillyTavern && \
    npm install \
" || print_error "npm install 失败！请检查网络或日志输出。"
print_success "依赖安装完成。"

# 步骤 6: 下载管理器脚本
print_step "6/6" "正在下载管理器脚本..."
MANAGER_URL="https://raw.githubusercontent.com/${GH_USER}/${GH_REPO}/main/${MANAGER_SCRIPT}"
curl -o "$HOME/$MANAGER_SCRIPT" "${MANAGER_URL}" || print_error "下载管理器脚本失败！"
chmod +x "$HOME/$MANAGER_SCRIPT"
print_success "管理器脚本下载成功。"

echo
echo "--------------------------------------------------------"
echo -e "\033[1;32m🎉 恭喜！SillyTavern 已全部署成功！ 🎉\033[0m"
echo "--------------------------------------------------------"
echo "现在，您可以通过运行下面的命令来启动和管理 SillyTavern："
echo
echo -e "  \033[1;33m./${MANAGER_SCRIPT}\033[0m"
echo

