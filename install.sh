#!/bin/bash

# ==============================================================================
# SillyTavern Termux 一键安装脚本 (JH-Installer v7.1 - 无人值班版)
#
# 作者: JiHe (纪贺) & Gemini
# 仓库: https://github.com/ignite661/JH-SillyTavern-Manager
#
# 更新日志 (v7.1):
# - 修复: 增加 --force-confnew 选项，解决因配置文件冲突导致的安装暂停问题。
#              现在脚本已实现真正的“无人值守”全自动安装。
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
echo -e "${C_WHITE}  SillyTavern Termux 原生环境一键安装脚本 (无人值班版)  ${C_RESET}"
echo -e "${C_CYAN}=====================================================${C_RESET}"
echo
echo -e "本脚本将自动完成所有必要步骤，包括："
echo -e "1. 安装 ${C_GREEN}Git, Node.js (LTS), pnpm${C_RESET} 等核心依赖。"
echo -e "2. 从官方仓库克隆 ${C_GREEN}SillyTavern${C_RESET}。"
echo -e "3. 安装所有项目依赖。"
echo -e "4. 创建一个功能强大且界面美观的 ${C_GREEN}管理器 (jh_manager.sh)${C_RESET}。"
echo
read -p "按 Enter 键开始安装，按 Ctrl+C 中止..."

# --- 步骤 1: 安装核心依赖 ---
echo -e "\n${C_YELLOW}>>> [1/4] 正在更新软件包并安装核心依赖...${C_RESET}"
# 关键修复：使用 --force-confnew 选项避免因配置文件冲突而暂停
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
echo -e "\n${C_YELLOW}>>> [2/4] 正在从 GitHub 克隆 SillyTavern...${C_RESET}"
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
echo -e "\n${C_YELLOW}>>> [3/4] 正在安装项目依赖，这可能需要几分钟...${C_RESET}"
cd SillyTavern
if ! pnpm install; then
    echo -e "\n${C_RED}错误: 'pnpm install' 执行失败！${C_RESET}"
    exit 1
fi
cd ..
echo -e "${C_GREEN}✓ 项目依赖安装成功！${C_RESET}"

# --- 步骤 4: 创建智能管理器 ---
echo -e "\n${C_YELLOW}>>> [4/4] 正在创建智能管理器 (jh_manager.sh)...${C_RESET}"
cat << 'EOF' > "$HOME/jh_manager.sh"
#!/bin/bash

# --- 颜色定义 ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

# --- 全局变量 ---
TAVERN_DIR="$HOME/SillyTavern"

# --- 功能函数 ---
show_menu() {
    clear
    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo -e "${C_WHITE}         SillyTavern 智能管理器 v1.1          ${C_RESET}"
    echo -e "${C_WHITE}                  by 纪贺 & Gemini              ${C_RESET}"
    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo
    echo -e "  ${C_GREEN}1. 启动 SillyTavern${C_RESET}"
    echo -e "  ${C_BLUE}2. 更新 SillyTavern 到最新版${C_RESET}"
    echo -e "  ${C_BLUE}3. 重新安装依赖 (强制模式)${C_RESET}"
    echo
    echo -e "  ${C_YELLOW}q. 退出管理器${C_RESET}"
    echo -e "${C_CYAN}---------------------------------------------------${C_RESET}"
}

start_tavern() {
    echo -e "\n${C_YELLOW}>>> 正在尝试启动 SillyTavern...${C_RESET}"
    if [ ! -d "$TAVERN_DIR" ]; then
        echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}"
    elif [ ! -f "$TAVERN_DIR/server.js" ]; then
        echo -e "\n${C_RED}错误：找不到启动文件 server.js！可能是安装不完整。${C_RESET}"
    else
        cd "$TAVERN_DIR"
        echo -e "${C_WHITE}启动成功后，请在浏览器访问: http://127.0.0.1:8000 或 http://localhost:8000${C_RESET}"
        echo -e "${C_WHITE}在 Termux 中按 Ctrl+C 即可停止运行。${C_RESET}"
        echo -e "${C_CYAN}-------------------- LOGS --------------------${C_RESET}"
        npm start
        echo -e "${C_CYAN}----------------------------------------------${C_RESET}"
        echo -e "\n${C_RED}SillyTavern 已关闭或启动失败。${C_RESET}"
    fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}"
    read
}

update_tavern() {
    echo -e "\n${C_YELLOW}>>> 正在更新 SillyTavern...${C_RESET}"
    if [ -d "$TAVERN_DIR" ]; then
        cd "$TAVERN_DIR"
        git pull
        echo -e "\n${C_GREEN}更新完成！如果出现问题，建议使用选项3重新安装依赖。${C_RESET}"
    else
        echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}"
    fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}"
    read
}

reinstall_deps() {
    echo -e "\n${C_YELLOW}>>> 正在强制重新安装依赖...${C_RESET}"
    if [ -d "$TAVERN_DIR" ]; then
        cd "$TAVERN_DIR"
        echo "  正在删除旧的依赖 (node_modules)..."
        rm -rf node_modules
        echo "  正在使用 pnpm 重新安装，请耐心等待..."
        pnpm install
        echo -e "\n${C_GREEN}依赖重新安装完成！${C_RESET}"
    else
        echo -e "\n${C_RED}错误：未找到 SillyTavern 目录！${C_RESET}"
    fi
    echo -e "\n${C_WHITE}按 Enter键 返回主菜单...${C_RESET}"
    read
}

# --- 主循环 ---
while true; do
    show_menu
    read -p "请输入选项 [1-3, q]: " choice

    case $choice in
        1) start_tavern ;;
        2) update_tavern ;;
        3) reinstall_deps ;;
        q|Q)
            echo -e "\n${C_YELLOW}正在退出... 感谢使用！${C_RESET}"
            break ;;
        *)
            echo -e "\n${C_RED}无效的输入，请重新选择。${C_RESET}"
            sleep 1 ;;
    esac
done
EOF

# 赋予管理器脚本执行权限
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
