# agent-hid-x — 跨平台智能体（Agent）编程辅助硬件映射

将鼠标、迷你键盘等硬件输入映射为自定义快捷键，提升 PC 操作效率与 AI 编程助手的操作体验。

**跨平台支持**：
- **Linux**：使用 xremap（evdev/uinput）
- **Windows**：使用 AutoHotkey v2（AHK 配置位于 `windows/` 目录下）

## 设计目标

极客配置，本质是一组按键映射。不限工具、不限场景，用户拿到后想怎么配就怎么配。

默认提供的映射针对 **AI 编程助手** 优化（Claude Code / Codex / Gemini / MiMo 等），但你完全可以改成任何你想要的快捷键——直接告诉 LLM 即可。

如果你也在用 AI 编程工具且使用 Linux，这套硬件方案可以让你**用极低成本（≈¥52）获得高效的操作体验**。

## 给大语言模型的说明

你可以将本文档直接交给大语言模型（如 Claude、GPT 等），它会：

1. **读取本文档**了解所有设备的按键映射
2. **按安装章节的步骤**自动完成安装
3. 如果你想**自定义映射**，只需告诉模型：

   > "把迷你键盘左侧①（Config 键）的映射改成 Ctrl+Shift+T"
   >
   > "把鼠标 X1（后退侧键）的映射改成 Ctrl+Shift+Esc"

   模型会修改 `config.yml` 并重启服务。

**无需手动编辑配置文件。**

## 配套语音输入法

本项目的**鼠标中键 / 迷你键盘 OK 键 按住 = Right Ctrl** 默认是为语音输入设计的。

配套语音输入法：[ibus-libpinyin-voice](https://github.com/wsyb/ibus-libpinyin-voice)

如果你使用其他语音输入法，直接告诉 LLM 你想改成什么快捷键即可（比如你的输入法是 Ctrl+Shift+F，LLM 会修改 `config.yml` 来匹配它）。不需要去改输入法软件的设置。

## 支持的设备

经测试的设备：

| 设备 | 型号 | 连接方式 | 参考成本 |
|------|------|----------|----------|
| 鼠标 | 英菲克 M9 无线鼠标 | 2.4G | ≈¥36 |
| 迷你键盘 | XING WEI 2.4G USB 迷你键盘 | USB | ≈¥12 |

**鼠标**：理论上任何有侧键（X1/X2）+ 中键（滚轮可按下）的鼠标都支持，不限型号。

**迷你键盘**：理论上任何标准 USB 或蓝牙连接的迷你键盘都支持，包括各种非标准布局的小键盘。

**蓝牙遥控器**：理论上支持任意蓝牙遥控器，不支持红外。

![英菲克 M9 鼠标](m9-mouse.jpeg)
![迷你键盘](mini-keyboard.jpeg)

## 功能概览

### ① 英菲克 M9 鼠标（通用鼠标方案）

**设计场景**：有时候单纯不想打字、不想按快捷键，只想轻轻动一下鼠标就完成桌面切换或语音说话。

> 适用于任何标准鼠标（不限于英菲克），只要有侧键 X1/X2 和中键即可。

| 物理操作 | 效果 | 用途 |
|----------|------|------|
| 按后退侧键 (X1) | 切换到右边工作区 | 右桌面 |
| 按前进侧键 (X2) | 切换到左边工作区 | 左桌面 |
| **按住中键** | **Right Ctrl 保持按住** | **语音输入：按住说话，松手文字上屏** |
| Ctrl + X1 | PageDown | 下翻一页 |
| Ctrl + X2 | PageUp | 上翻一页 |
| Alt + X1 | Alt+Right | 浏览器前进 |
| Alt + X2 | Alt+Left | 浏览器后退 |

> **中键说明**：中键是语音输入专用。按住时 Right Ctrl 持续按下，松开则释放。
> 配合语音输入程序的"按住说话"模式使用。

---

### ② 小米蓝牙语音遥控器

**⚠️ 已停用**。语音键硬件不发送标准 HID 事件，无法可靠映射。参考成本 ≈¥4。

**原始设计场景**：将电脑屏幕投屏到电视上，人在客厅手持遥控器开发。遥控器通过蓝牙连接 PC（非电视），实现远距离操作。

如果需要用遥控器语音输入，可手动启用关机键长按 → Right Ctrl 的映射（参考 `config.yml` 中鼠标中键的写法，在 `modmap` 段添加 `Code_116`，与鼠标中键逻辑相同），但当前版本未启用。

---

### ③ 迷你键盘（XING WEI）

布局说明：圆盘在左，右侧六键分两列（中间是触控板），每列三个按键。

**设计场景**：躺在床上开发，或抱着笔记本在公园长椅上开发。手不想碰全键盘、不想碰鼠标时，这个迷你键盘能满足几乎 100% 的操作需求，操作效率和使用体验不输全键盘 + 鼠标。

#### 圆盘四键（围绕 OK 键）

| 物理位置 | 按键图标（原始功能） | 映射为 |
|----------|---------------------|--------|
| OK 键按住 | 播放/暂停 (PlayPause) | Right Ctrl 按住 |
| ↑ 方向 | 上一曲 (PreviousSong) | 左边工作区 |
| → 方向 | 下一曲 (NextSong) | 右边工作区 |
| ← 方向 | 音量− (VolumeDown) | Ctrl+PageDown |
| ↓ 方向 | 音量+ (VolumeUp) | Ctrl+PageUp |

> 图标与映射逻辑不完全一一对应，以实际功能为准。

#### 左侧竖排三键

| 位置 | 原始键名 | 映射为 |
|------|---------|--------|
| ①（顶部） | Config（设置键） | Super+J |
| ②（中部） | Mail（邮件键） | Ctrl+J |
| ③（底部） | Mute（静音键） | Ctrl+C |

#### 右侧竖排三键

| 位置 | 原始键名 | 映射为 |
|------|---------|--------|
| ①（顶部） | Search（搜索键） | Shift+Tab |
| ②（中部） | HomePage（主页键） | Ctrl+T |
| ③（底部） | WWW（网页键） | Ctrl+W |

## 安装

### 前置依赖

```bash
# 1. 安装 Rust（如果还没有）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 2. 安装系统依赖
sudo apt install -y libx11-dev pkg-config

# 3. 编译安装 xremap（GNOME Wayland 必须带 --features gnome）
cargo install xremap --features gnome

# 4. 验证安装
xremap --version
```

> 如果你的环境不是 GNOME Wayland，请选择对应 feature：
> - `--features kde` → KDE-Plasma Wayland
> - `--features x11` → X11
> - `--features wlroots` → Sway / Hyprland

### 获取项目

```bash
# 方式一：克隆（如果已托管到 git）
git clone <仓库地址>
cd agent-hid-x

# 方式二：直接复制到本地
cp -r /path/to/agent-hid-x ~/agent-hid-x
cd ~/agent-hid-x
```

### 检查设备名称

本项目默认匹配以下设备名：

- `2.4G Mouse` — 英菲克 M9 鼠标
- `Telink Madao` — Telink 无线键盘
- `XING WEI` — 迷你键盘
- `USB PnP Audio` — 音频设备媒体键

**你的设备名可能不同**，需要先查看：

```bash
# 查看所有输入设备
xremap --list-devices 2>&1 | grep -i "mouse\|keyboard\|consumer\|composite"
# 或
ls /dev/input/by-id/ | grep -i "mouse\|keyboard"
```

如果设备名不同，运行 install.sh 时传入你实际的设备名：

```bash
bash systemd/install.sh "你的鼠标名" "你的键盘名"
```

### 一键安装

```bash
chmod +x systemd/install.sh
bash systemd/install.sh
```

脚本会：
1. 复制 `config.yml` 到 `~/.config/xremap/`
2. 生成 systemd 服务文件
3. 设置 sudoers（**需要输入 sudo 密码**）
4. 启用并启动 xremap 服务

### 手动安装

如果不想用 install.sh：

```bash
# 1. 复制配置
mkdir -p ~/.config/xremap
cp config.yml ~/.config/xremap/

# 2. 创建 systemd 服务
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/xremap.service << EOF
[Unit]
Description=xremap 按键映射
After=graphical-session.target

[Service]
ExecStart=/usr/bin/sudo $(which xremap) --watch --device "设备名1" --device "设备名2" /home/$USER/.config/xremap/config.yml
Restart=on-failure
Type=simple

[Install]
WantedBy=default.target
EOF

# 3. 设置 sudoers（免密码执行 xremap）
echo "$USER ALL=(ALL) NOPASSWD: $(which xremap)" | sudo tee /etc/sudoers.d/xremap
sudo chmod 440 /etc/sudoers.d/xremap

# 4. 启用服务
systemctl --user daemon-reload
systemctl --user enable --now xremap
```

### 验证安装

```bash
systemctl --user status xremap     # 应为 active (running)
journalctl --user -u xremap -n 10  # 查看启动日志
```

### 卸载

```bash
systemctl --user stop xremap
systemctl --user disable xremap
rm -f ~/.config/systemd/user/xremap.service
sudo rm -f /etc/sudoers.d/xremap
systemctl --user daemon-reload
```

## 如何适配新设备

不要猜测按键名称。使用附带的检测工具：

```bash
# 1. 停掉 xremap（独占输入设备）
systemctl --user stop xremap

# 2. 运行检测器
/usr/bin/python3 ./scripts/key_detector.py

# 3. 按每个要映射的键，记录 code=NNNN

# 4. 在 config.yml 中写入 Code_NNN: 目标快捷键

# 5. 重启 xremap
systemctl --user start xremap
```

**永远使用 `Code_NNN` 格式**（如 `Code_171: Super-J`），不要猜测按键名字。
检测器会显示精确的 code，数字索引不存在歧义。

## 项目结构

```
agent-hid-x/
  ├── README.md
  ├── config.yml         # Linux (xremap)
  ├── windows/
  │   └── config.ahk     # Windows (AutoHotkey v2)
  ├── scripts/
  │   └── key_detector.py
  └── systemd/
      └── install.sh
```

## 常见问题

### 安装后按键没有反应

```bash
# 1. 检查服务是否运行
systemctl --user status xremap

# 2. 查看启动日志
journalctl --user -u xremap -n 30

# 3. 检查设备是否被选中（日志中应有你的设备名）
#    如果没看到"Selected devices matching"，说明设备名不对
```

### 服务起不来（sudo 权限）

```bash
# 验证 sudoers 文件是否存在
sudo cat /etc/sudoers.d/xremap

# 如果不存在，手动创建
echo "$USER ALL=(ALL) NOPASSWD: $(which xremap)" | sudo tee /etc/sudoers.d/xremap
sudo chmod 440 /etc/sudoers.d/xremap
```

### 设备名不对

```bash
# 查看所有输入设备
xremap --list-devices

# 找到你的鼠标/键盘名字，修改 install.sh 中的 PATTERNS 数组
```

### 按键映射不对

使用 `key_detector.py` 重新检测设备实际发送的 code，然后用 `Code_NNN` 格式写配置。

## 许可

MIT
