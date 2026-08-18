# 纪贺SillyTavern管理器 (JH-SillyTavern-Manager)

一个为 Termux 用户量身打造的 SillyTavern 一键部署与管理工具，旨在提供最简单、最流畅的本地AI体验。

## ✨ 项目特色

*   **一键安装**: 只需一行命令，即可全自动完成 SillyTavern 的环境配置、程序下载和依赖安装，真正做到全程零交互。
*   **沉浸式管理**: 安装完成后，每次打开 Termux 应用都会自动进入专属管理系统，操作直观方便。
*   **轻量快速**: 原生 Termux 环境直跑，不依赖 proot 容器；管理系统启动零网络请求，秒开不卡顿。
*   **数据安全**: 内置备份/恢复功能，角色卡、聊天记录、世界书等重要数据一键打包。
*   **客户端整包更新**: 更新机制基于 GitHub Release 整包同步，以后新增文件、新功能也能一次更新到位，无需重新部署。
*   **完全免费与开源**: 本项目完全免费，并以开源精神分享。严禁任何形式的商业倒卖行为。

## 🚀 快速开始

在您的 Termux 环境中，复制并粘贴以下命令，然后按回车键即可开始全自动安装：

```bash
pkg update -y && DEBIAN_FRONTEND=noninteractive pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && DEBIAN_FRONTEND=noninteractive pkg install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl && curl -sSL https://raw.githubusercontent.com/ignite661/JH-SillyTavern-Manager/main/install.sh | bash
```

> 🧙 **全程自动，不需要你做任何选择**：命令里已经加了 `--force-confdef --force-confold`，即使出现配置文件冲突也会自动保留现有配置，不会弹出 `Y/I/N/O/D/Z` 这类询问。
>
> ⚠️ **为什么必须先升级**：纯净 Termux 直接安装 curl 会把 curl 升级到新版，但 openssl/libngtcp2 没同步升级会导致 curl 动态链接损坏，从而无法下载安装脚本。所以必须先 `pkg upgrade`。
>
> 💡 安装脚本内部也会再次执行 `pkg upgrade` 和依赖安装，并自动处理 Termux 常见兼容问题（如 openssl/curl 冲突、pnpm 构建脚本、Node LTS 等）。

安装过程大约需要5-10分钟，具体取决于您的网络和设备性能。

## 📖 使用说明

安装成功后，脚本会自动为您设置“沉浸式启动”。

*   **每次打开 Termux 应用**，都会直接进入【纪贺 SillyTavern 管理系统】。
*   在管理系统中，输入对应的数字即可执行操作。
*   若想退出管理系统并使用原始的 Termux 命令行，只需按 `q` 键退出。

### 管理系统功能

```
 1. 打开酒馆          - 启动 SillyTavern，浏览器访问 http://127.0.0.1:8000
 2. 检查酒馆更新      - 手动拉取最新版酒馆并同步依赖
 3. 重新安装依赖      - 解决更新后依赖异常
 4. 备份数据          - 打包角色卡、聊天记录、世界书等数据
 5. 恢复数据          - 从备份文件恢复酒馆数据
 6. 检查脚本更新      - 整包更新安装/管理/更新脚本
 7. 查看更新公告      - 查看项目最新消息与更新内容
 q. 退出管理系统
```

> 💡 所有联网操作均为**手动触发**，管理系统启动时不会访问网络，大陆用户也能秒开。

## 🔄 更新机制

### 更新脚本（推荐）

在管理系统中选择 **`6. 检查脚本更新`**，或手动执行：

```bash
bash ~/update.sh
```

新版更新机制特点：

* 从 GitHub Release 下载 **整包 `jh-update.zip`**，一次同步所有脚本文件
* 以后即使新增文件、新模块，老用户也能一次更新到位
* 下载后自动做语法校验，失败不会覆盖旧文件
* 更新前自动备份旧脚本，出问题可回退
* 如果提示“已是最新”，仍可选择强制重新下载

### 更新酒馆

在管理系统中选择 **`2. 检查酒馆更新`**，会自动 `git pull --rebase --autostash` 并同步依赖。

## 🛠️ 常见问题

### 启动酒馆时 webpack 编译报错（`Cannot read properties of undefined (reading '0')`）

如果你遇到酒馆前端编译失败、`lib.js` 找不到，请先确认：

```bash
node -v
```

建议使用 Termux 的 **LTS 版本**：

```bash
pkg install -y nodejs-lts
```

并清理缓存后重装依赖：

```bash
cd ~/SillyTavern
rm -rf data/_webpack node_modules
echo "dangerouslyAllowAllBuilds: true" >> pnpm-workspace.yaml
pnpm install --dangerously-allow-all-builds
pnpm start
```

> 如果问题仍然存在，请将终端报错发送给作者，后续会通过客户端更新推送修复。

## ⚠️ 重要声明

本脚本及管理器由作者 **纪贺 (ignite661)** 开发，完全 **免费** 提供给所有爱好者使用。

**警告：如果您是付费购买得到的本脚本，说明您已被骗！** 请立即向卖家要求退款，并共同抵制这种可耻的盗卖行为！

## 🐞 问题反馈

如果您在使用过程中遇到任何Bug或有好的建议，欢迎通过以下邮箱联系我：

*   **作者邮箱**: `wjj373247085@163.com`

感谢每一位用户的支持与信任！
