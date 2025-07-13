#!/bin/bash

# ==============================================================================
# SillyTavern 启动/管理脚本 (JH-Manager v2.0 - pnpm 驱动版)
#
# 作者: 纪贺科技 (ignite661)
# 仓库: https://github.com/ignite661/JH-SillyTavern-Manager
#
# v2.0: 全面转向 pnpm。使用 pnpm 启动和管理依赖，更高效、更稳定。
#       代码已简化，不再需要指定 npm 的绝对路径。
# ==============================================================================

# --- 函数 ---
start_st() {
    echo "正在启动 SillyTavern (pnpm 模式)..."
    echo "请等待约 10-30 秒，直到看到 'SillyTavern is listening on port 7860' 或类似字样。"
    echo "然后请在手机浏览器中访问: http://127.0.0.1:7860"
    echo "--------------------------------------------------------"
    
    # 使用 pnpm 启动，更高效
    proot-distro login ubuntu --shared-tmp -- bash -c " \
        cd /root/SillyTavern && \
        pnpm start \
    "
    echo "--------------------------------------------------------"
    echo "SillyTavern 已关闭或启动失败。"
}

update_st() {
    echo "正在更新 SillyTavern..."
    proot-distro login ubuntu -- bash -c "cd /root/SillyTavern && git pull"
    echo "--------------------------------------------------------"
    echo "更新完成。如果看到 'Already up to date.' 说明已是最新版。"
}

reinstall_deps() {
    echo "正在使用 pnpm 重新安装依赖..."
    echo "这会比 npm 快很多，请耐心等待。"
    
    # 使用 pnpm 重装依赖
    proot-distro login ubuntu --shared-tmp -- bash -c " \
        cd /root/SillyTavern && \
        rm -rf node_modules && \
        pnpm install \
    "
    echo "--------------------------------------------------------"
    echo "依赖重装完成。"
}

# --- 主菜单 ---
while true; do
    clear
    echo "========================================"
    echo "  纪贺 SillyTavern 管理器 (v2.0 pnpm)"
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
