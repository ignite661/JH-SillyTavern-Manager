#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键部署脚本 (JH-Installer v2.4 - 硬编码路径终极版)
#
# 作者: 纪贺科技 (ignite661)
# 仓库: https://github.com/ignite661/JH-SillyTavern-Manager
#
# v2.4: 使用硬编码路径代替 'proot-distro path'，以兼容因系统限制
#       而未能成功升级到最新版的旧版 proot-distro。这是最终解决方案。
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
echo "欢迎使用纪贺科技 SillyTavern 一键部署脚本 (v2.4 终极版)"
echo "--------------------------------------------------------"
echo "此脚本已针对您的特殊环境进行优化，成功率极高！"
echo "部署过程可能需要 10-20 分钟，请耐心等待..."
sleep 4

# 步骤 1: 准备 Termux 环境
print_step "1/6" "正在更新并安装 Termux 基础环境..."
pkg update -y && pkg upgrade -y
pkg install proot-distro git curl -y
print_success "Termux 基础环境准备完毕。"


# 步骤 2: 清理并安装 Ubuntu
print_step "2/6" "正在安装 Ubuntu 容器..."
# 检查 proot-distro 是否存在
if ! command -v proot-distro >/dev/null 2>&1; then
    print_error "核心依赖 'proot-distro' 未安装！请检查步骤1的输出。"
fi

proot-distro remove ubuntu &>/dev/null
proot-distro install ubuntu || print_error "Ubuntu 安装失败！请检查网络。"

# 【终极修正】直接使用硬编码的默认路径，不再依赖 'proot-distro path'
ubuntu_root="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

if [ ! -d "$ubuntu_root" ]; then
   print_error "未能找到 Ubuntu 安装路径: ${ubuntu_root}。安装可能已失败。"
fi
print_success "Ubuntu 容器安装成功，路径确认！"

# 步骤 3: 部署 SillyTavern 源码
print_step "3/6" "正在部署 SillyTavern..."
if [ -d "$ubuntu_root/root/SillyTavern" ]; then
    rm -rf "$ubuntu_root/root/SillyTavern"
fi
# 使用 Termux 的 git 直接操作 Ubuntu 的文件系统
git clone https://github.com/SillyTavern/SillyTavern.git "$ubuntu_root/root/SillyTavern" || print_error "SillyTavern 克隆失败！"
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

