#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v8.0 - 不死鸟版)
#
# 作者: JiHe (纪贺) & Gemini
# 仓库: https://github.com/ignite661/JH-SillyTavern-Manager
#
# 更新日志 (v8.0):
# - 不死鸟修复: 增加自动切换 Termux 软件源的功能，优先使用清华大学镜像源，
#              从根源上解决因官方或阿里源不稳定导致的安装失败问题。
#              这使得脚本在各种网络环境下都具有极高的成功率。
# ==============================================================================

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

# --- 欢迎信息 ---
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo -e "${C_WHITE}  SillyTavern Termux 一键安装脚本 (不死鸟最终版)  ${C_RESET}"
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo
echo -e "本脚本将自动完成所有必要步骤，包括："
echo -e "1. ${C_YELLOW}(重要) 自动切换到更稳定的清华大学软件源。${C_RESET}"
echo -e "2. 安装 ${C_GREEN}Git, Node.js (LTS), pnpm${C_RESET} 等核心依赖。"
echo -e "3. 从官方仓库克隆 ${C_GREEN}SillyTavern${C_RESET}。"
echo -e "4. 安装所有项目依赖。"
echo -e "5. 创建一个功能强大且界面美观的 ${C_GREEN}管理器 (jh_manager.sh)${C_RESET}。"
echo
read -p "按 Enter 键开始安装，按 Ctrl+C 中止..."

# --- 步骤 0: 切换到稳定的清华镜像源 ---
echo -e "\n${C_YELLOW}>>> [0/5] 正在切换到清华大学软件源以提高稳定性...${C_RESET}"
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list
# 可选：处理其他源（如果存在）
if [ -f "$PREFIX/etc/apt/sources.list.d/science.list" ]; then
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/science-packages-24 stable main@' $PREFIX/etc/apt/sources.list.d/science.list
fi
if [ -f "$PREFIX/etc/apt/sources.list.d/game.list" ]; then
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/game-packages-24 stable main@' $PREFIX/etc/apt/sources.list.d/game.list
fi
echo -e "${C_GREEN}✓ 软件源切换完成！${C_RESET}"

# --- 步骤 1: 安装核心依赖 ---
echo -e "\n${C_YELLOW}>>> [1/5] 正在更新软件包列表并安装核心依赖...${C_RESET}"
pkg update -y && pkg upgrade -o Dpkg::Options::="--force-confnew" -y
pkg install git nodejs-lts pnpm -y

# 验证
if ! command -v node &> /dev/null || ! command -v pnpm &> /dev/null; then
    echo -e "\n${C_RED}致命错误: Node.js 或 pnpm 未能成功安装！脚本中止。${C_RESET}"
    exit 1
fi
echo -e "${C_GREEN}✓ 核心依赖安装成功！${C_RESET}"
echo -n "  Node.js 版本: "; node -v
echo -n "  pnpm 版本: "; pnpm -v

# --- 步骤 2: 克隆 SillyTavern 仓库 ---
echo -e "\n${C_YELLOW}>>> [2/5] 正在从 GitHub 克隆 SillyTavern...${C_RESET}"
if [ -d "SillyTavern" ]; then
    echo "  检测到已存在的 SillyTavern 目录，跳过克隆。"
else
    if ! git clone https://github.com/SillyTavern/SillyTavern.git; then
        echo -e "\n${C_RED}错误: 克隆 SillyTavern 失败！请检查您的网络连接。${C_RESET}"
        exit 1
    fi
fi
echo -e "${C_GREEN}✓ SillyTavern 克隆完成！${C_RESET}"

# --- 步骤 3: 安装项目依赖 ---
echo -e "\n${C_YELLOW}>>> [3/5] 正在安装项目依赖，这可能需要几分钟...${C_RESET}"
cd SillyTavern
if ! pnpm install; then
    echo -e "\n${C_RED}错误: 'pnpm install' 执行失败！${C_RESET}"
    exit 1
fi
cd ..
echo -e "${C_GREEN}✓ 项目依赖安装成功！${C_RESET}"

# --- 步骤 4: 创建智能管理器 ---
echo -e "\n${C_YELLOW}>>> [4/5] 正在创建智能管理器 (jh_manager.sh)...${C_RESET}"
# (这部分代码和之前一样，无需改动)
cat << 'EOF' > "$HOME/jh_manager.sh"
#!/bin/bash
# --- 颜色定义 ---
C_RESET='\033[0m';C_RED='\033[0;31m';C_GREEN='\033[0;32m';C_YELLOW='\033[0;33m';C_BLUE='\033[0;34m';C_CYAN='\033[0;36m';C_WHITE='\033[1;37m'
TAVERN_DIR="$HOME/SillyTavern"
show_menu() {
    clear;echo -e "${C_CYAN}===================================================${C_RESET}";echo -e "${C_WHITE}         SillyTavern 智能管理器 v1.2          ${C_RESET}";echo -e "${C_WHITE}                  by 纪贺 & Gemini              ${C_RESET}";echo -e "${C_CYAN}===================================================${C_RESET}";echo;echo -e "  ${C_GREEN}1. 启动 SillyTavern${C_RESET}";echo -e "  ${C_BLUE}2. 更新 SillyTavern 到最新版${C_RESET}";echo -e "  ${C_BLUE}3. 重新安装依赖 (强制模式)${C_RESET}";echo;echo -e "  ${C_YELLOW}q. 退出管理器${C_RESET}";echo -e "${C_CYAN}---------------------------------------------------${C_RESET}"
}
start_tavern() {
    echo -e "\n${C_YELLOW}>>> 正在尝试启动 SillyTavern...${C_RESET}";if [ ! -d "$TAVERN_DIR" ]; then echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}";elif [ ! -f "$TAVERN_DIR/server.js" ]; then echo -e "\n${C_RED}错误：找不到启动文件 server.js！可能是安装不完整。${C_RESET}";else
    cd "$TAVERN_DIR";echo -e "${C_WHITE}启动成功后，请在浏览器访问: http://127.0.0.1:8000 或 http://localhost:8000${C_RESET}";echo -e "${C_WHITE}在 Termux 中按 Ctrl+C 即可停止运行。${C_RESET}";echo -e "${C_CYAN}-------------------- LOGS --------------------${C_RESET}";npm start;echo -e "${C_CYAN}----------------------------------------------${C_RESET}";echo -e "\n${C_RED}SillyTavern 已关闭或启动失败。${C_RESET}";fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}";read
}
update_tavern() {
    echo -e "\n${C_YELLOW}>>> 正在更新 SillyTavern...${C_RESET}";if [ -d "$TAVERN_DIR" ]; then cd "$TAVERN_DIR";git pull;echo -e "\n${C_GREEN}更新完成！如果出现问题，建议使用选项3重新安装依赖。${C_RESET}";else echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}";fi;echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}";read
}
reinstall_deps() {
    echo -e "\n${C_YELLOW}>>> 正在强制重新安装依赖...${C_RESET}";if [ -d "$TAVERN_DIR" ]; then cd "$TAVERN_DIR";echo "  正在删除旧的依赖 (node_modules)...";rm -rf node_modules;echo "  正在使用 pnpm 重新安装，请耐心等待...";pnpm install;echo -e "\n${C_GREEN}依赖重新安装完成！${C_RESET}";else echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}";fi;echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}";read
}
while true; do show_menu;read -p "请输入选项 [1-3, q]: " choice;case $choice in 1) start_tavern ;; 2) update_tavern ;; 3) reinstall_deps ;; q|Q) echo -e "\n${C_YELLOW}正在退出... 感谢使用！${C_RESET}";break ;; *) echo -e "\n${C_RED}无效的输入，请重新选择。${C_RESET}";sleep 1 ;;esac;done
EOF

chmod +x "$HOME/jh_manager.sh"
echo -e "${C_GREEN}✓ 智能管理器创建成功！${C_RESET}"

# --- 安装完成 ---
echo
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo -e "${C_GREEN}    🎉🎉🎉 恭喜！SillyTavern 已全部安装完成！ 🎉🎉🎉    ${C_RESET}"
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo
echo -e "现在，请使用我们为您创建的专属管理器来操作："
echo -e "  1. 在命令行输入 ${C_YELLOW}./jh_manager.sh${C_RESET}"
echo -e "  2. 在弹出的菜单中选择 ${C_GREEN}'1'${C_RESET} 即可启动！"
echo
