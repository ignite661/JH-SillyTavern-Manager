#!/bin/bash

# ==============================================================================
# SillyTavern 启动/管理脚本 (JH-Manager v3.0 - Termux 原生版)
#
# 作者: 纪贺科技 (ignite661) & 您
#
# v3.0: 终极简化版。所有命令直接在 Termux 中执行，不再需要 proot-distro。
#       这是与原生安装脚本配套的管理器。
# ==============================================================================

ST_DIR_NAME="SillyTavern"

# --- 函数 ---
start_st() {
    echo "正在启动 SillyTavern (原生模式)..."
    echo "请等待约 10-30 秒，直到看到 'SillyTavern is listening on port 7860' 或类似字样。"
    echo "然后请在手机浏览器中访问: http://127.0.0.1:7860"
    echo "--------------------------------------------------------"
    
    if [ -d "$ST_DIR_NAME" ]; then
        cd "$ST_DIR_NAME" && pnpm start
    else
        echo "错误: 未找到 SillyTavern 目录！"
    fi
    echo "--------------------------------------------------------"
    echo "SillyTavern 已关闭或启动失败。"
}

update_st() {
    echo "正在更新 SillyTavern..."
    if [ -d "$ST_DIR_NAME" ]; then
        cd "$ST_DIR_NAME" && git pull && cd ..
    else
        echo "错误: 未找到 SillyTavern 目录！"
    fi
    echo "--------------------------------------------------------"
    echo "更新完成。如果看到 'Already up to date.' 说明已是最新版。"
}

reinstall_deps() {
    echo "正在使用 pnpm 重新安装依赖..."
    if [ -d "$ST_DIR_NAME" ]; then
        cd "$ST_DIR_NAME"
        rm -rf node_modules
        pnpm install
        cd ..
    else
        echo "错误: 未找到 SillyTavern 目录！"
    fi
    echo "--------------------------------------------------------"
    echo "依赖重装完成。"
}

# --- 主菜单 ---
while true; do
    clear
    echo "========================================"
    echo "  纪贺 SillyTavern 管理器 (v3.0 原生)"
    echo "========================================"
    echo " 1. 启动 SillyTavern"
    echo " 2. 更新 SillyTavern"
    echo " 3. 重新安装依赖 (pnpm模式)"
    echo " q. 退出"
    echo "----------------------------------------"
    read -p "请输入选项 [1-3, q]: " choice

    case $choice in
        1)
            start_st
            read -p "按 Enter键 返回主菜单..."
            ;;
        2)
            update_st
            read -p "按 Enter键 返回主菜单..."
            ;;
        3)
            reinstall_deps
            read -p "按 Enter键 返回主菜单..."
            ;;
        q)
            echo "正在退出..."
            break
            ;;
        *)
            echo "无效选项，请重试。"
            sleep 1
            ;;
    esac
done
