#!/usr/bin/env bash
# ==============================================================================
# Omarchy Agenda 插件辅助安装脚本 (可选)
# 作用: 将核心 CLI 脚本软链至 ~/.local/bin，并可选安装 systemd 用户服务
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="$HOME/.local/bin/omarchy-calendar-sync"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_TARGET="$SERVICE_DIR/omarchy-calendar-sync.service"

mkdir -p "$HOME/.local/bin" "$SERVICE_DIR"

echo "==> 链接 CLI 脚本至 $BIN_TARGET..."
ln -sf "$SCRIPT_DIR/scripts/omarchy-calendar-sync" "$BIN_TARGET"
chmod +x "$BIN_TARGET"

echo "==> 初始化日历配置模版 (~/.config/omarchy/calendars.json)..."
"$BIN_TARGET" --init >/dev/null 2>&1 || true

echo "==> 是否配置 systemd 用户守护服务? (Omarchy 插件已默认内置 Service.qml 自动同步)"
read -r -p "安装并启用 systemd 用户服务? [y/N]: " choice || choice="n"
if [[ "$choice" =~ ^[Yy]$ ]]; then
    cp "$SCRIPT_DIR/systemd/omarchy-calendar-sync.service" "$SERVICE_TARGET"
    systemctl --user daemon-reload
    systemctl --user enable --now omarchy-calendar-sync.service
    echo "==> systemd 用户服务已就绪并启动！"
fi

echo "==> 安装完成！运行 'omarchy-calendar-sync --status' 即可查看日程。"
