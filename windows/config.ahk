; ============================================================
; agent-hid-x  Windows 主配置
; 鼠标 + 迷你键盘 按键映射
; AutoHotkey v2 — 配合 https://github.com/wsyb/agent-hid-x
; ============================================================
; 映射说明见项目 README.md「功能概览」章节，Linux/Windows 保持一致。
; ============================================================

#SingleInstance Force
SendMode "Input"

; ==================== 1. 鼠标映射 ====================

; --- Ctrl + 滚轮：翻页 ---
$^WheelDown::Send("{Blind}{PgDn}")
$^WheelUp::Send("{Blind}{PgUp}")

; --- Alt + 侧键：浏览器前进/后退（支持长按连续） ---
$!XButton1::
{
    Send("{Blind}{Alt down}{Right down}")
    KeyWait("XButton1")
    Send("{Blind}{Right up}")
}

$!XButton2::
{
    Send("{Blind}{Alt down}{Left down}")
    KeyWait("XButton2")
    Send("{Blind}{Left up}")
}

; --- Win + 左键：任务视图（Win+Tab） ---
$#LButton::
{
    Send("{LWin up}")
    Send("#{Tab}")
}

; --- 单按侧键：切换虚拟桌面 ---
XButton1::Send("^#{Right}")
XButton2::Send("^#{Left}")


; ==================== 2. 迷你键盘（XING WEI / 媒体键）映射 ====================

; --- 主键盘媒体播放/暂停键：奇数次 Win+H，偶数次 Esc ---
Media_Play_Pause::
{
    static toggle := false
    toggle := !toggle
    if (toggle)
        Send("#h")
    else
        Send("{Esc}")
}

; --- 圆盘四键（映射与 Linux config.yml 一致） ---
Media_Prev::Send("^#{Left}")     ; 上一曲 → 左桌面
Media_Next::Send("^#{Right}")    ; 下一曲 → 右桌面
Volume_Up::Send("^{PgUp}")       ; 音量+ → Ctrl+PgUp（终端上一个标签）
Volume_Down::Send("^{PgDn}")     ; 音量− → Ctrl+PgDn（终端下一个标签）

; --- 左侧竖排两键 ---
Launch_Media::Send("#{Tab}")     ; Config → 任务视图
Launch_Mail::Send("^j")          ; Mail → Ctrl+J（coding agent 换行）

; --- 右侧竖排两键 ---
Browser_Search::Send("+{Tab}")   ; Search → Shift+Tab
Browser_Home::Send("^t")         ; HomePage → Ctrl+T

; --- 其他 ---
Volume_Mute::Send("^c")          ; Mute → Ctrl+C（复制 / 终端终止）

; --- Alt+W → Ctrl+W（关闭标签页） ---
!w::Send("{Alt up}^w")
