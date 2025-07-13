#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键部署脚本 (JH-Installer v2.6 - 绝对路径终极必杀版)
#
# 作者: 纪贺科技 (ignite661)
# 仓库: https://github.com/ignite661/JH-SillyTavern-Manager
#
# v2.6: 终极解决方案。针对 proot-distro 不加载 .bashrc 的极端情况，
#       所有 npm/node 命令全部使用绝对路径调用，绕过 PATH 环境变量问题。
# ==============================================================================

# --- 配置 ---
GH_USER="ignite661"
GH_REPO="JH-SillyTavern-Manager"
NODE_VERSION="v20.12.2"
NODE_DIR_NAME="node-${NODE_VERSION}-linux-arm64"
NODE_ARCHIVE="${NODE_DIR_NAME}.tar.xz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_ARCHIVE}"
MANAGER_SCRIPT="jh_manager.sh"

# --- 函数定义 ---
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
echo "欢迎使用纪贺科技 SillyTavern 一键部署脚本 (v2.6 终极必杀版)"
echo "--------------------------------------------------------"
echo "此脚本将使用最稳妥的方式进行安装！"
sleep 4

# 步骤 1 & 2: 环境和 Ubuntu 安装
print_step "1-2/6" "准备环境并安装 Ubuntu..."
pkg update -y && pkg upgrade -y &>/dev/null
pkg install proot-distro git curl -y &>/dev/null
proot-distro remove ubuntu &>/dev/null
proot-distro install ubuntu || print_error "Ubuntu 安装失败！"
ubuntu_root="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$ubuntu_root" ]; then
   print_error "未能找到 Ubuntu 安装路径。"
fi
print_success "Ubuntu 安装成功。"

# 步骤 3: 部署 SillyTavern 源码
print_step "3/6" "正在部署 SillyTavern..."
if [ -d "$ubuntu_root/root/SillyTavern" ]; then
    rm -rf "$ubuntu_root/root/SillyTavern"
fi
git clone https://github.com/SillyTavern/SillyTavern.git "$ubuntu_root/root/SillyTavern" || print_error "SillyTavern 克隆失败！"
print_success "SillyTavern 源码部署成功。"

# 步骤 4: 部署 Node.js
print_step "4/6" "正在部署 Node.js..."
proot-distro login ubuntu --shared-tmp -- bash -c " \
    cd /root && \
    curl -L -o ${NODE_ARCHIVE} ${NODE_URL} && \
    tar -xf ${NODE_ARCHIVE} && \
    rm ${NODE_ARCHIVE} \
" || print_error "Node.js 下载或解压失败！"
print_success "Node.js 文件部署成功。"

# 步骤 5: 安装 SillyTavern 依赖 (使用绝对路径)
print_step "5/6" "正在安装 SillyTavern 依赖 (终极模式)..."
echo "这一步耗时最长，请保持耐心"
# 【终极修正】直接使用绝对路径调用 npm，不再依赖环境变量
NPM_PATH="/root/${NODE_DIR_NAME}/bin/npm"
proot-distro login ubuntu --shared-tmp -- bash -c " \
    cd /root/SillyTavern && \
    ${NPM_PATH} install \
" || print_error "npm install 失败！这超出预期，请截图反馈。"
print_success "依赖安装完成！我们成功了最难的一步！"

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
