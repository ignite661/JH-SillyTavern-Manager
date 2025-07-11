#!/bin/bash

clear
echo -e "\033[1;36m欢迎使用纪贺的SillyTavern管理脚本 v1.0 (Ubuntu版)\033[0m"
echo -e "\033[1;33m适配Ubuntu系统\033[0m"
echo "======================================"
echo -e "\033[1;35m作者: 纪贺\033[0m"
echo "======================================"

ST_DIR="$HOME/SillyTavern"
CONFIG_FILE="$HOME/.jh_tavern_config"
BACKUP_DIR="$HOME/jh_tavern_backups"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "PORT=8000" > "$CONFIG_FILE"
    echo "CONTEXT_SIZE=4096" >> "$CONFIG_FILE"
fi

source "$CONFIG_FILE"

mkdir -p "$BACKUP_DIR"

function show_header() {
    clear
    echo -e "\033[1;36m纪贺的酒馆管理助手 (Ubuntu版)\033[0m"
    echo -e "\033[0;33m因为你们不看群公告故怒而写出此脚本 - 由纪贺打造\033[0m"
    echo "======================================"
}

function install_dependencies() {
    show_header
    echo -e "\033[1;33m纪贺正在为你安装必要组件...\033[0m"
    
    sudo apt update
    sudo apt install -y nodejs npm git python3
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;32m纪贺正在下载SillyTavern...\033[0m"
        git clone https://github.com/SillyTavern/SillyTavern.git "$ST_DIR"
        cd "$ST_DIR"
        npm install
    fi
    
    echo -e "\033[1;32m纪贺已完成所有组件安装！\033[0m"
    sleep 2
}

function start_tavern() {
    show_header
    echo -e "\033[1;33m纪贺正在启动你的专属酒馆...\033[0m"
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;31m未检测到SillyTavern，纪贺将为你安装\033[0m"
        install_dependencies
    fi
    
    cd "$ST_DIR"
    
    echo -e "\033[1;32m纪贺的酒馆即将开业！端口: $PORT\033[0m"
    echo -e "\033[1;34m按Ctrl+C可以关闭酒馆\033[0m"
    
    # 尝试打开浏览器，如果失败则提示手动访问
    xdg-open "http://localhost:$PORT" > /dev/null 2>&1 || echo "请在浏览器中访问 http://localhost:$PORT"
    
    node server.js --port $PORT --context-size $CONTEXT_SIZE
}

function update_tavern() {
    show_header
    echo -e "\033[1;33m纪贺正在为你更新酒馆...\033[0m"
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;31m未检测到SillyTavern安装，纪贺将为你安装\033[0m"
        install_dependencies
        return
    fi
    
    BACKUP_NAME="st_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    
    echo -e "\033[1;34m纪贺正在备份你的数据...\033[0m"
    cp -r "$ST_DIR/public/characters" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/chats" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/settings" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/groups" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/worlds" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    
    echo -e "\033[1;34m纪贺正在获取最新版本...\033[0m"
    cd "$ST_DIR"
    git pull
    npm install
    
    echo -e "\033[1;32m纪贺已成功更新你的酒馆！\033[0m"
    sleep 2
}

function backup_tavern() {
    show_header
    echo -e "\033[1;33m纪贺正在为你备份酒馆数据...\033[0m"
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;31m未检测到SillyTavern安装，无法备份\033[0m"
        sleep 2
        return
    fi
    
    BACKUP_NAME="jh_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    
    echo -e "\033[1;34m纪贺正在创建备份...\033[0m"
    cp -r "$ST_DIR/public/characters" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/chats" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/settings" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/groups" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    cp -r "$ST_DIR/public/worlds" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    
    echo -e "\033[1;32m纪贺已完成备份！保存在: $BACKUP_DIR/$BACKUP_NAME\033[0m"
    sleep 2
}

function restore_backup() {
    show_header
    echo -e "\033[1;33m纪贺的备份恢复向导\033[0m"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        echo -e "\033[1;31m纪贺没有找到任何备份\033[0m"
        sleep 2
        return
    fi
    
    echo "纪贺找到了以下备份:"
    
    local i=1
    local backups=()
    
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            echo "$i) $(basename "$backup")"
            backups+=("$backup")
            ((i++))
        fi
    done
    
    echo "0) 返回"
    
    echo -e "\033[1;36m请输入备份编号:\033[0m"
    read -r choice
    
    if [ "$choice" = "0" ]; then
        return
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
        selected=${backups[$choice-1]}
        
        echo -e "\033[1;33m纪贺正在恢复备份: $(basename "$selected")\033[0m"
        
        if [ -d "$selected/characters" ]; then
            cp -r "$selected/characters" "$ST_DIR/public/" 2>/dev/null
        fi
        if [ -d "$selected/chats" ]; then
            cp -r "$selected/chats" "$ST_DIR/public/" 2>/dev/null
        fi
        if [ -d "$selected/settings" ]; then
            cp -r "$selected/settings" "$ST_DIR/public/" 2>/dev/null
        fi
        if [ -d "$selected/groups" ]; then
            cp -r "$selected/groups" "$ST_DIR/public/" 2>/dev/null
        fi
        if [ -d "$selected/worlds" ]; then
            cp -r "$selected/worlds" "$ST_DIR/public/" 2>/dev/null
        fi
        
        echo -e "\033[1;32m纪贺已成功恢复你的数据！\033[0m"
        sleep 2
    else
        echo -e "\033[1;31m输入错误，请重试\033[0m"
        sleep 2
    fi
}

function settings_menu() {
    while true; do
        show_header
        echo -e "\033[1;33m纪贺的酒馆设置中心\033[0m"
        echo "======================================"
        echo -e "\033[1;36m1) 修改端口 (当前: $PORT)\033[0m"
        echo -e "\033[1;36m2) 修改上下文长度 (当前: $CONTEXT_SIZE)\033[0m"
        echo -e "\033[1;36m0) 返回主菜单\033[0m"
        echo "======================================"
        echo -e "\033[1;35m纪贺在等待你的选择:\033[0m"
        
        read -r choice
        
        case $choice in
            1)
                echo -e "\033[1;36m请输入新的端口号:\033[0m"
                read -r new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]]; then
                    sed -i "s/PORT=.*/PORT=$new_port/" "$CONFIG_FILE"
                    source "$CONFIG_FILE"
                    echo -e "\033[1;32m纪贺已更新端口设置！\033[0m"
                else
                    echo -e "\033[1;31m输入错误，端口必须是数字\033[0m"
                fi
                sleep 2
                ;;
            2)
                echo -e "\033[1;36m请输入新的上下文长度:\033[0m"
                read -r new_size
                if [[ "$new_size" =~ ^[0-9]+$ ]]; then
                    sed -i "s/CONTEXT_SIZE=.*/CONTEXT_SIZE=$new_size/" "$CONFIG_FILE"
                    source "$CONFIG_FILE"
                    echo -e "\033[1;32m纪贺已更新上下文长度！\033[0m"
                else
                    echo -e "\033[1;31m输入错误，上下文长度必须是数字\033[0m"
                fi
                sleep 2
                ;;
            0)
                return
                ;;
            *)
                echo -e "\033[1;31m选项不存在，请重试\033[0m"
                sleep 2
                ;;
        esac
    done
}

if [ ! -d "$ST_DIR" ]; then
    install_dependencies
fi

while true; do
    show_header
    echo -e "\033[1;33m纪贺的酒馆管理菜单\033[0m"
    echo "======================================"
    echo -e "\033[1;36m1) 启动酒馆\033[0m"
    echo -e "\033[1;36m2) 更新酒馆\033[0m"
    echo -e "\033[1;36m3) 备份数据\033[0m"
    echo -e "\033[1;36m4) 恢复备份\033[0m"
    echo -e "\033[1;36m5) 酒馆设置\033[0m"
    echo -e "\033[1;36m0) 退出\033[0m"
    echo "======================================"
    echo -e "\033[1;35m纪贺在等待你的选择:\033[0m"
    
    read -r choice
    
    case $choice in
        1)
            start_tavern
            ;;
        2)
            update_tavern
            ;;
        3)
            backup_tavern
            ;;
        4)
            restore_backup
            ;;
        5)
            settings_menu
            ;;
        0)
            clear
            echo -e "\033[1;32m感谢使用纪贺的SillyTavern管理脚本，下次再见！\033[0m"
            exit 0
            ;;
        *)
            echo -e "\033[1;31m选项不存在，请重试\033[0m"
            sleep 2
            ;;
    esac
done
