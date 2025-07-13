#!/bin/bash

ST_DIR="/root/SillyTavern"
BACKUP_DIR="/root/jh_tavern_backups"
LOG_FILE="/root/jh_install_log.txt"
AUTOSTART_FLAG_FILE="/root/.autostart_enabled"

NODE_VERSION="18.19.1"
NODE_ARCH="arm64"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
NODE_DIR_NAME="node-v${NODE_VERSION}-linux-${NODE_ARCH}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[1;36m'
NC='\033[0m'

function check_dependencies() {
    echo -e "${YELLOW}>> 正在初始化并检查运行环境，请稍候...${NC}"
    apt-get update >/dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -y git curl build-essential python3 >/dev/null 2>&1

    if ! command -v node &>/dev/null || [[ $(node -v | cut -d'v' -f2) != "${NODE_VERSION}" ]]; then
        echo -e "${YELLOW}>> 首次运行，正在为您配置必要的 Node.js (v${NODE_VERSION}) 环境...${NC}"
        cd /root
        rm -rf "$NODE_DIR_NAME" "node.tar.xz"
        curl -L -o node.tar.xz "$NODE_URL"
        tar -xf node.tar.xz
        sed -i '/node.*arm64\/bin/d' /root/.bashrc
        echo "export PATH=\$PATH:/root/${NODE_DIR_NAME}/bin" >> /root/.bashrc
        export PATH=$PATH:/root/$NODE_DIR_NAME/bin
        rm node.tar.xz
        echo -e "${GREEN}>> 环境配置完成！${NC}"
    fi
}

function install_tavern() {
    echo -e "${CYAN}>> 正在从 GitHub 下载 SillyTavern，请保持网络通畅...${NC}"
    echo "安装日志已记录到: ${LOG_FILE}" > "$LOG_FILE"
    
    if [ -d "$ST_DIR" ]; then
        echo -e "${YELLOW}   检测到 SillyTavern 已存在，跳过下载。${NC}"
    else
        git clone https://github.com/SillyTavern/SillyTavern.git "$ST_DIR" >> "$LOG_FILE" 2>&1
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            echo -e "${RED}   下载失败！请检查网络或查看日志文件: ${LOG_FILE}${NC}"; read -p "按回车键返回。"; return 1;
        fi
    fi
    
    cd "$ST_DIR"
    echo -e "${YELLOW}>> 正在安装程序依赖，这可能需要几分钟，请耐心等待...${NC}"
    if npm install --loglevel=error >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}>> SillyTavern 成功安装！现在您可以从主菜单启动它了。${NC}"
    else
        echo -e "${RED}>> 依赖安装失败！这通常是网络问题。请检查日志以获取详细信息: ${LOG_FILE}${NC}";
    fi
    read -p "按回车键返回主菜单..."
}

function start_tavern() {
    if [ ! -f "$ST_DIR/server.js" ]; then
        echo -e "${RED}错误：SillyTavern 尚未安装。请在主菜单选择安装选项。${NC}"; sleep 2; return;
    fi
    pkill -f "node server.js"
    
    cd "$ST_DIR"
    local port=$(grep 'port:' config.yaml | awk '{print $2}' 2>/dev/null || echo "8000")
    
    clear
    echo -e "${GREEN}>> SillyTavern 正在启动...${NC}"
    echo -e "   现在，您可以在手机浏览器中访问以下地址:"
    echo -e "   ${CYAN}--> http://localhost:${port} <--${NC}"
    echo -e "\n   ${RED}提示：当您想关闭酒馆时，回到这个界面，然后按键盘上的 Ctrl 和 C 键。${NC}"
    
    node server.js
    
    echo -e "\n${YELLOW}>> 酒馆服务已停止。正在返回主菜单...${NC}"; sleep 2
}

function settings_menu() {
    if [ ! -f "$ST_DIR/config.yaml" ]; then
        echo -e "${RED}错误：找不到配置文件。请先完整安装并至少启动一次SillyTavern。${NC}"; sleep 2; return;
    fi
    
    while true; do
        local current_port=$(grep 'port:' $ST_DIR/config.yaml | awk '{print $2}' 2>/dev/null || echo "未设置")
        local autostart_status
        if [ -f "$AUTOSTART_FLAG_FILE" ]; then
            autostart_status="${GREEN}已开启${NC}"
        else
            autostart_status="${RED}已关闭${NC}"
        fi
        
        clear
        echo -e "${CYAN}--- 酒馆高级设置 ---${NC}"
        echo "--------------------------------------------------"
        echo -e " 1) 修改访问端口     (当前: ${YELLOW}${current_port}${NC})"
        echo -e " 2) 重新安装依赖       (用于修复一些奇怪的启动问题)"
        echo -e " 9) Termux自启面板   (当前: ${autostart_status})"
        echo -e " 0) ${RED}返回主菜单${NC}"
        echo "--------------------------------------------------"
        read -p "请输入您的选择: " choice
        
        case $choice in
            1)
                read -p "请输入您想使用的新端口号 (纯数字，例如 8000): " new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]]; then
                    sed -i "s/port: .*/port: $new_port/" "$ST_DIR/config.yaml"
                    echo -e "${GREEN}操作成功！端口已更新为 ${new_port}${NC}"; sleep 2
                else
                    echo -e "${RED}输入错误！请输入一个有效的数字。${NC}"; sleep 2
                fi
                ;;
            2)
                read -p "确认要重新安装所有依赖吗？这将花费几分钟时间。(y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    echo -e "${YELLOW}正在清理并重新安装依赖...${NC}"
                    cd "$ST_DIR" && rm -rf node_modules && npm install
                    echo -e "${GREEN}依赖已成功重新安装！${NC}"; sleep 2
                else
                    echo "操作已取消。"; sleep 2
                fi
                ;;
            9)
                if [ -f "$AUTOSTART_FLAG_FILE" ]; then
                    rm "$AUTOSTART_FLAG_FILE"
                    echo -e "${GREEN}Termux 自动启动面板功能已关闭。${NC}"
                else
                    touch "$AUTOSTART_FLAG_FILE"
                    echo -e "${GREEN}Termux 自动启动面板功能已开启。${NC}"
                fi
                sleep 2
                ;;
            0) break ;;
            *) echo -e "${RED}无效的选项，请重新输入。${NC}"; sleep 1 ;;
        esac
    done
}

function backup_data() {
    echo -e "${CYAN}>> 正在备份您的角色、聊天记录和设置...${NC}"
    mkdir -p "$BACKUP_DIR"
    local backup_file="${BACKUP_DIR}/st_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_folders=( "public/backgrounds" "public/characters" "public/chats" "public/groups" "public/worlds" "public/settings.json" "public/instruct" )
    cd "$ST_DIR"
    if tar -czvf "$backup_file" "${backup_folders[@]}"; then
        echo -e "${GREEN}>> 备份成功！您的数据已安全保存。${NC}"
        echo "备份文件位于: $backup_file"
    else
        echo -e "${RED}>> 备份失败！请检查存储空间。${NC}"
    fi
    read -p "按回车键返回主菜单..."
}

function restore_data() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        echo -e "${RED}错误：未找到任何可用的备份文件。${NC}"; sleep 2; return;
    fi

    echo -e "${CYAN}--- 请选择您要恢复的备份文件 ---${NC}"
    select backup_file in "$BACKUP_DIR"/*.tar.gz; do
        if [ -n "$backup_file" ]; then
            read -p "警告：这将覆盖您当前的数据！确认要恢复吗？(y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${YELLOW}>> 正在从 ${backup_file##*/} 中恢复数据...${NC}"
                cd "$ST_DIR"
                if tar -xzvf "$backup_file"; then
                    echo -e "${GREEN}>> 数据恢复成功！${NC}"
                else
                    echo -e "${RED}>> 恢复过程中发生错误！${NC}"
                fi
                read -p "按回车键返回主菜单..."; break
            else
                echo "操作已取消。"; read -p "按回车键返回主菜单..."; break
            fi
        else
            echo -e "${RED}无效的选择！${NC}"; sleep 2; break
        fi
    done
}

check_dependencies

while true; do
    clear
    echo -e "${CYAN}--- 欢迎来到 纪贺的SillyTavern管理面板 ---${NC}"
    echo -e "${BLUE}======================================================${NC}"
    
    if [ ! -f "$ST_DIR/server.js" ]; then
        echo -e " ${YELLOW}您好！看起来这是您第一次使用，请先安装酒馆:${NC}"
        echo -e "\n   1) ${GREEN}[必需] 一键安装 SillyTavern${NC}\n"
    else
        echo -e " ${GREEN}请选择您要进行的操作:${NC}\n"
        echo -e "   1) ${GREEN}启动酒馆，开始聊天${NC}"
        echo -e "   2) ${CYAN}酒馆高级设置${NC}"
        echo -e "   3) ${CYAN}更新酒馆到最新版本${NC}"
        echo -e "   4) ${YELLOW}备份数据 (保护您的心血)${NC}"
        echo -e "   5) ${YELLOW}从备份中恢复数据${NC}"
    fi
    
    echo ""
    echo -e "   6) 查看安装日志 (用于排查疑难杂症)"
    echo -e "   0) ${RED}退出面板 (返回到Termux命令行)${NC}"
    echo -e "${BLUE}------------------------------------------------------${NC}"
    read -p "请输入数字并按回车: " choice
    
    case $choice in
        1) [ ! -f "$ST_DIR/server.js" ] && install_tavern || start_tavern ;;
        2) settings_menu ;;
        3) 
            echo -e "${YELLOW}正在从 GitHub 拉取最新更新...${NC}"
            cd "$ST_DIR" && git pull && echo -e "${GREEN}>> 更新完成，正在同步依赖...${NC}" && npm install --loglevel=error
            echo -e "${GREEN}>> 操作完成! SillyTavern 已是最新版。${NC}"; sleep 2
            ;;
        4) backup_data ;;
        5) restore_data ;;
        6) clear; cat "$LOG_FILE" || echo "日志文件为空。"; read -p "按回车键返回。";;
        0) break ;;
        *) echo -e "${RED}输入错误，请输入菜单中显示的数字。${NC}"; sleep 1 ;;
    esac
done

echo -e "${CYAN}感谢您的使用！已退出管理面板。${NC}"
echo "您可以输入 'start-tavern' 再次进入。"
exit 0
