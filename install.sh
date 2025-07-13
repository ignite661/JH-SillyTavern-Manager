#!/bin/bash

MANAGER_SCRIPT_URL="https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/jh_manager.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}欢迎使用 纪贺的SillyTavern一键安装器！ (v1.1 修正版)${NC}"
echo "本程序将为您自动配置一个稳定、高效的运行环境。"
echo "======================================================================="
sleep 2

echo -e "${YELLOW}>> 步骤 1/5: 准备基础工具...${NC}"
pkg update -y >/dev/null 2>&1
pkg install git proot-distro -y

UBUNTU_ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOTFS" ]; then
    echo -e "${YELLOW}>> 步骤 2/5: 正在安装隔离的 Ubuntu 运行环境...${NC}"
    echo "   这个过程可能需要几分钟，取决于您的网络速度，请耐心等待。"
    proot-distro install ubuntu
    if [ ! -d "$UBUNTU_ROOTFS" ]; then
        echo -e "${RED}环境安装失败！请检查您的网络连接或 Termux 存储权限后重试。${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}>> 步骤 2/5: 检测到 Ubuntu 环境已存在。${NC}"
fi

echo -e "${YELLOW}>> 步骤 3/5: 正在下载核心管理程序...${NC}"
MANAGER_SCRIPT_PATH="${UBUNTU_ROOTFS}/root/jh_manager.sh"
# 修正: 将 'exec' 改为 'login'
proot-distro login ubuntu -- /bin/bash -c "curl -s -L -o /root/jh_manager.sh ${MANAGER_SCRIPT_URL} && chmod +x /root/jh_manager.sh"

if [ ! -f "$MANAGER_SCRIPT_PATH" ]; then
    echo -e "${RED}核心管理程序下载失败！请确认您的网络可以访问 GitHub。${NC}"
    exit 1
fi
echo -e "${GREEN}>> 步骤 3/5: 管理程序已就绪！${NC}"

echo -e "${YELLOW}>> 步骤 4/5: 正在创建快速启动命令 'start-tavern'...${NC}"
cat << 'EOF' > "$PREFIX/bin/start-tavern"
#!/bin/bash
proot-distro login ubuntu -- /root/jh_manager.sh
EOF
chmod +x "$PREFIX/bin/start-tavern"
echo -e "${GREEN}>> 快速启动命令已创建！${NC}"

echo -e "${YELLOW}>> 步骤 5/5: 正在设置 Termux 启动时自动进入管理面板...${NC}"
AUTOSTART_FLAG_FILE="${UBUNTU_ROOTFS}/root/.autostart_enabled"
BASHRC_FILE="$HOME/.bashrc"

# 修正: 将 'exec' 改为 'login'
# 创建自启标志文件
proot-distro login ubuntu -- touch "$AUTOSTART_FLAG_FILE"

# 检查并添加自启代码到 .bashrc
if ! grep -q "# JH SillyTavern Auto-start" "$BASHRC_FILE"; then
    cat << 'EOF' >> "$BASHRC_FILE"

# JH SillyTavern Auto-start
# This block was added by ignite661's script.
# It checks for a flag file and launches the manager if it exists.
if [ -f "/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/.autostart_enabled" ]; then
  # Clear screen and launch, so it looks clean
  clear
  start-tavern
fi
EOF
    echo -e "${GREEN}>> 已成功设置开机自启！${NC}"
else
    echo -e "${GREEN}>> 开机自启配置已存在，跳过。${NC}"
fi

echo -e "\n${GREEN}>> 所有安装步骤已完成！${NC}"
echo -e "从现在起，每次您打开 Termux，都会自动进入管理面板。"
echo -e "如果想临时使用 Termux 命令行，可以在面板中选择'退出'。"
echo -e "如果想永久关闭自启，请在面板的高级选项中设置。"
echo -e "\n>> 即将进入【纪贺的酒馆管理系统】...${NC}"
sleep 5

exec start-tavern
