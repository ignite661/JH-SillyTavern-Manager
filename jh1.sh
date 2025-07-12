#!/bin/bash

clear
echo -e "\033[1;36m欢迎使用纪贺的酒馆管理脚本 v1.0\033[0m"
echo -e "\033[1;33m为Android Termux环境专业定制\033[0m"
echo "======================================"
echo -e "\033[1;35m作者: 纪贺\033[0m"
echo "======================================"

# 基本配置
ST_DIR="$HOME/SillyTavern"
CONFIG_FILE="$HOME/.jh_tavern_config"
BACKUP_DIR="$HOME/jh_tavern_backups"

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo "PORT=8000" > "$CONFIG_FILE"
    echo "CONTEXT_SIZE=4096" >> "$CONFIG_FILE"
fi

source "$CONFIG_FILE"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 显示头部信息
function show_header() {
    clear
    echo -e "\033[1;36m纪贺的SillyTavern管理系统\033[0m"
    echo -e "\033[0;33m专业的Termux酒馆管理解决方案 - 由纪贺开发\033[0m"
    echo "======================================"
}

# 检查必要工具
function check_dependencies() {
    for cmd in git curl nodejs npm; do
        if ! command -v $cmd &>/dev/null; then
            echo -e "\033[1;33m检测到缺少必要组件: $cmd，正在安装...\033[0m"
            pkg update -y
            pkg install -y $cmd
        fi
    done
    
    # 检查Node.js版本
    if command -v node &>/dev/null; then
        node_version=$(node -v | cut -d 'v' -f 2)
        echo -e "\033[0;32mNode.js版本: $node_version\033[0m"
    fi
}

# 安装依赖
function install_dependencies() {
    show_header
    echo -e "\033[1;33m系统正在安装必要组件...\033[0m"
    
    # 检查并安装基础依赖
    check_dependencies
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;32m正在下载SillyTavern...\033[0m"
        if git clone https://github.com/SillyTavern/SillyTavern.git "$ST_DIR"; then
            cd "$ST_DIR"
            echo -e "\033[1;32m正在安装依赖项...\033[0m"
            if npm install; then
                echo -e "\033[1;32m依赖安装成功！\033[0m"
            else
                echo -e "\033[1;31m依赖安装失败，请检查网络连接或Node.js版本\033[0m"
                return 1
            fi
        else
            echo -e "\033[1;31mSillyTavern下载失败，请检查网络连接\033[0m"
            return 1
        fi
    fi
    
    echo -e "\033[1;32m所有组件安装完成！\033[0m"
    sleep 2
    return 0
}

# 启动酒馆
function start_tavern() {
    show_header
    echo -e "\033[1;33m正在启动您的专属酒馆...\033[0m"
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;31m未检测到SillyTavern，系统将为您安装\033[0m"
        install_dependencies || return 1
    fi
    
    cd "$ST_DIR"
    
    echo -e "\033[1;32m酒馆即将开业！端口: $PORT\033[0m"
    echo -e "\033[1;34m按Ctrl+C可以关闭酒馆\033[0m"
    
    # 尝试在浏览器中打开
    am start -a android.intent.action.VIEW -d "http://localhost:$PORT" > /dev/null 2>&1
    
    # 启动服务器
    node server.js --port $PORT --context-size $CONTEXT_SIZE
}

# 更新酒馆
function update_tavern() {
    show_header
    echo -e "\033[1;33m正在更新您的酒馆...\033[0m"
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;31m未检测到SillyTavern安装，系统将为您安装\033[0m"
        install_dependencies
        return
    fi
    
    # 创建备份
    BACKUP_NAME="st_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    
    echo -e "\033[1;34m正在备份您的数据...\033[0m"
    
    # 备份重要数据
    if [ -d "$ST_DIR/public/characters" ]; then
        cp -r "$ST_DIR/public/characters" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    fi
    
    if [ -d "$ST_DIR/public/chats" ]; then
        cp -r "$ST_DIR/public/chats" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    fi
    
    if [ -d "$ST_DIR/public/settings" ]; then
        cp -r "$ST_DIR/public/settings" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    fi
    
    if [ -d "$ST_DIR/public/groups" ]; then
        cp -r "$ST_DIR/public/groups" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    fi
    
    if [ -d "$ST_DIR/public/worlds" ]; then
        cp -r "$ST_DIR/public/worlds" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
    fi
    
    echo -e "\033[1;34m正在获取最新版本...\033[0m"
    cd "$ST_DIR"
    
    # 获取当前版本
    current_version=$(grep '"version"' package.json 2>/dev/null | sed -E 's/.*"version": "([^"]+)".*/\1/')
    echo -e "\033[0;33m当前版本: $current_version\033[0m"
    
    # 更新代码
    if git pull; then
        # 获取更新后的版本
        new_version=$(grep '"version"' package.json 2>/dev/null | sed -E 's/.*"version": "([^"]+)".*/\1/')
        echo -e "\033[0;32m更新后版本: $new_version\033[0m"
        
        # 安装依赖
        echo -e "\033[1;34m正在更新依赖...\033[0m"
        if npm install; then
            echo -e "\033[1;32m酒馆已成功更新！\033[0m"
        else
            echo -e "\033[1;31m依赖更新失败，请检查网络连接\033[0m"
        fi
    else
        echo -e "\033[1;31m更新失败，请检查网络连接\033[0m"
    fi
    
    sleep 2
}

# 备份酒馆数据
function backup_tavern() {
    show_header
    echo -e "\033[1;33m正在备份酒馆数据...\033[0m"
    
    if [ ! -d "$ST_DIR" ]; then
        echo -e "\033[1;31m未检测到SillyTavern安装，无法备份\033[0m"
        sleep 2
        return
    fi
    
    # 创建备份目录
    BACKUP_NAME="jh_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    
    echo -e "\033[1;34m正在创建备份...\033[0m"
    
    # 备份各种数据
    local backup_success=false
    
    if [ -d "$ST_DIR/public/characters" ]; then
        cp -r "$ST_DIR/public/characters" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
        backup_success=true
    fi
    
    if [ -d "$ST_DIR/public/chats" ]; then
        cp -r "$ST_DIR/public/chats" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
        backup_success=true
    fi
    
    if [ -d "$ST_DIR/public/settings" ]; then
        cp -r "$ST_DIR/public/settings" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
        backup_success=true
    fi
    
    if [ -d "$ST_DIR/public/groups" ]; then
        cp -r "$ST_DIR/public/groups" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
        backup_success=true
    fi
    
    if [ -d "$ST_DIR/public/worlds" ]; then
        cp -r "$ST_DIR/public/worlds" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null
        backup_success=true
    fi
    
    if [ "$backup_success" = true ]; then
        echo -e "\033[1;32m备份已完成！保存在: $BACKUP_DIR/$BACKUP_NAME\033[0m"
    else
        echo -e "\033[1;33m未找到可备份的数据\033[0m"
        rmdir "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null
    fi
    
    sleep 2
}

# 恢复备份
function restore_backup() {
    show_header
    echo -e "\033[1;33m备份恢复向导\033[0m"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        echo -e "\033[1;31m未找到任何备份\033[0m"
        sleep 2
        return
    fi
    
    echo "系统找到了以下备份:"
    
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
        
        echo -e "\033[1;33m正在恢复备份: $(basename "$selected")\033[0m"
        
        # 检查SillyTavern是否已安装
        if [ ! -d "$ST_DIR" ]; then
            echo -e "\033[1;31m未检测到SillyTavern安装，系统将为您安装\033[0m"
            install_dependencies || return
        fi
        
        # 恢复各种数据
        local restore_success=false
        
        if [ -d "$selected/characters" ]; then
            cp -r "$selected/characters" "$ST_DIR/public/" 2>/dev/null
            restore_success=true
        fi
        
        if [ -d "$selected/chats" ]; then
            cp -r "$selected/chats" "$ST_DIR/public/" 2>/dev/null
            restore_success=true
        fi
        
        if [ -d "$selected/settings" ]; then
            cp -r "$selected/settings" "$ST_DIR/public/" 2>/dev/null
            restore_success=true
        fi
        
        if [ -d "$selected/groups" ]; then
            cp -r "$selected/groups" "$ST_DIR/public/" 2>/dev/null
            restore_success=true
        fi
        
        if [ -d "$selected/worlds" ]; then
            cp -r "$selected/worlds" "$ST_DIR/public/" 2>/dev/null
            restore_success=true
        fi
        
        if [ "$restore_success" = true ]; then
            echo -e "\033[1;32m数据已成功恢复！\033[0m"
        else
            echo -e "\033[1;33m备份中未找到可恢复的数据\033[0m"
        fi
        
        sleep 2
    else
        echo -e "\033[1;31m输入错误，请重试\033[0m"
        sleep 2
    fi
}

# 设置菜单
function settings_menu() {
    while true; do
        show_header
        echo -e "\033[1;33m酒馆设置中心\033[0m"
        echo "======================================"
        echo -e "\033[1;36m1) 修改端口 (当前: $PORT)\033[0m"
        echo -e "\033[1;36m2) 修改上下文长度 (当前: $CONTEXT_SIZE)\033[0m"
        echo -e "\033[1;36m3) 检查系统环境\033[0m"
        echo -e "\033[1;36m0) 返回主菜单\033[0m"
        echo "======================================"
        echo -e "\033[1;35m请选择操作:\033[0m"
        
        read -r choice
        
        case $choice in
            1)
                echo -e "\033[1;36m请输入新的端口号:\033[0m"
                read -r new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                    sed -i "s/PORT=.*/PORT=$new_port/" "$CONFIG_FILE"
                    source "$CONFIG_FILE"
                    echo -e "\033[1;32m端口设置已更新！\033[0m"
                else
                    echo -e "\033[1;31m输入错误，端口必须是1-65535之间的数字\033[0m"
                fi
                sleep 2
                ;;
            2)
                echo -e "\033[1;36m请输入新的上下文长度:\033[0m"
                read -r new_size
                if [[ "$new_size" =~ ^[0-9]+$ ]]; then
                    sed -i "s/CONTEXT_SIZE=.*/CONTEXT_SIZE=$new_size/" "$CONFIG_FILE"
                    source "$CONFIG_FILE"
                    echo -e "\033[1;32m上下文长度已更新！\033[0m"
                else
                    echo -e "\033[1;31m输入错误，上下文长度必须是数字\033[0m"
                fi
                sleep 2
                ;;
            3)
                show_header
                echo -e "\033[1;33m系统环境检查\033[0m"
                echo "======================================"
                
                # 检查系统信息
                echo -e "\033[1;36m操作系统:\033[0m $(uname -a)"
                
                # 检查Node.js
                if command -v node &>/dev/null; then
                    echo -e "\033[1;36mNode.js版本:\033[0m $(node -v)"
                else
                    echo -e "\033[1;31mNode.js未安装\033[0m"
                fi
                
                # 检查npm
                if command -v npm &>/dev/null; then
                    echo -e "\033[1;36mnpm版本:\033[0m $(npm -v)"
                else
                    echo -e "\033[1;31mnpm未安装\033[0m"
                fi
                
                # 检查git
                if command -v git &>/dev/null; then
                    echo -e "\033[1;36mgit版本:\033[0m $(git --version)"
                else
                    echo -e "\033[1;31mgit未安装\033[0m"
                fi
                
                # 检查SillyTavern版本
                if [ -f "$ST_DIR/package.json" ]; then
                    st_version=$(grep '"version"' "$ST_DIR/package.json" 2>/dev/null | sed -E 's/.*"version": "([^"]+)".*/\1/')
                    echo -e "\033[1;36mSillyTavern版本:\033[0m $st_version"
                else
                    echo -e "\033[1;31mSillyTavern未安装或版本信息不可用\033[0m"
                fi
                
                # 检查存储空间
                echo -e "\033[1;36m存储空间:\033[0m"
                df -h | grep -E "Filesystem|/$"
                
                echo "======================================"
                echo -e "\033[1;35m按任意键返回\033[0m"
                read -n 1
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

# 检查是否首次运行
if [ ! -d "$ST_DIR" ]; then
    echo -e "\033[1;33m首次运行检测，正在进行初始化...\033[0m"
    install_dependencies
fi

# 主菜单循环
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
    echo -e "\033[1;35m请选择操作:\033[0m"
    
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
