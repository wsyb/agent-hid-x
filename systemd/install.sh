#!/bin/bash
# xremap-config 安装脚本
# 用法：./install.sh [设备匹配名...]
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── 自动检测 ──
USER="${SUDO_USER:-$USER}"
XREMAP_BIN="$(which xremap 2>/dev/null || echo "$HOME/.cargo/bin/xremap")"

if [ ! -x "$XREMAP_BIN" ]; then
    echo "错误: 找不到 xremap (尝试了: $XREMAP_BIN)"
    echo "请先安装: cargo install xremap --features gnome"
    exit 1
fi

# ── 设备匹配名（可按需覆盖）──
PATTERNS=(
    "2.4G Mouse"
    "Telink Madao"
    "XING WEI"
    "USB PnP Audio"
)

if [ $# -gt 0 ]; then
    PATTERNS=("$@")
fi

echo "==> 用户: $USER"
echo "==> xremap: $XREMAP_BIN"
echo "==> 设备:"
for p in "${PATTERNS[@]}"; do echo "      $p"; done

# ── 复制配置 ──
echo "==> 复制配置..."
cp "$PROJECT_DIR/config.yml" ~/.config/xremap/config.yml
chmod 644 ~/.config/xremap/config.yml

# ── 生成 service 文件 ──
echo "==> 部署 xremap 服务..."
SERVICE_FILE="$HOME/.config/systemd/user/xremap.service"
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" << SERVICE
[Unit]
Description=xremap 按键映射 (xremap-config)
After=graphical-session.target

[Service]
ExecStart=/usr/bin/sudo $XREMAP_BIN --watch $(IFS=""; for p in "${PATTERNS[@]}"; do echo -n " --device \"$p\""; done | sed 's/^ //') /home/$USER/.config/xremap/config.yml
Restart=on-failure
Type=simple

[Install]
WantedBy=default.target
SERVICE

# ── sudoers ──
echo "==> 设置 sudoers..."
SUDOERS_FILE="/etc/sudoers.d/xremap"

# 删除旧的（如果存在）
if [ -f "$SUDOERS_FILE" ]; then
    sudo rm -f "$SUDOERS_FILE"
fi

echo "$USER ALL=(ALL) NOPASSWD: $XREMAP_BIN" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 440 "$SUDOERS_FILE"

# ── 启用 ──
echo "==> 启用服务..."
systemctl --user daemon-reload
systemctl --user enable --now xremap

echo "==> 完成！"