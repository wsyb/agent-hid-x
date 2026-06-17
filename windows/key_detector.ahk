#SingleInstance Force
#Requires AutoHotkey >=2.0
InstallKeybdHook
Persistent

myGui := Gui("+AlwaysOnTop +ToolWindow", "按键检测")
myGui.SetFont("s12")
txt := myGui.Add("Edit", "w750 h300 ReadOnly",
    "E 键已映射为 Ctrl+W (关闭标签)`n"
    "按下 E 键即可在浏览器中关闭当前标签`n"
    "───────────────────────────────────")
myGui.Add("Button", "x10 w120", "清空").OnEvent("Click", (*) => txt.Value := "")
myGui.Add("Button", "x+10 w130", "按键历史").OnEvent("Click", (*) => KeyHistory())
myGui.Add("Button", "x+10 w130", "卸载钩子").OnEvent("Click", UninstallHook)
myGui.Show("x0 y0")

appCmdMap := Map(
    1, "Browser_Back", 2, "Browser_Forward", 3, "Browser_Refresh", 4, "Browser_Stop",
    5, "Browser_Search", 6, "Browser_Favorites", 7, "Browser_Home",
    8, "Volume_Mute", 9, "Volume_Down", 10, "Volume_Up",
    11, "Media_Next", 12, "Media_Prev", 13, "Media_Stop", 14, "Media_Play_Pause",
    15, "Launch_Mail", 16, "Launch_Media", 17, "Launch_App1", 18, "Launch_App2"
)

; ==================== 底层键盘钩子 (WH_KEYBOARD_LL) ====================
g_hHook := 0
g_hookActive := true

InstallHook() {
    global g_hHook
    if (g_hHook)
        return
    g_hHook := DllCall("SetWindowsHookEx"
        , "int", 13                      ; WH_KEYBOARD_LL
        , "ptr", CallbackCreate(LLProc)
        , "ptr", DllCall("GetModuleHandle", "ptr", 0, "ptr")
        , "uint", 0
        , "ptr")
    txt.Value .= (g_hHook ? "✓ 底层钩子已安装`n" : "⚠ 钩子安装失败`n")
}

UninstallHook(*) {
    global g_hHook
    if (g_hHook)
        DllCall("UnhookWindowsHookEx", "ptr", g_hHook)
    g_hHook := 0
    txt.Value .= "钩子已卸载`n"
}

LLProc(nCode, wParam, lParam) {
    global g_hHook, g_hookActive
    if (nCode < 0 || !g_hookActive)
        return DllCall("CallNextHookEx", "ptr", g_hHook, "int", nCode, "uint", wParam, "ptr", lParam)

    ; 只处理按键按下 (WM_KEYDOWN=0x100, WM_SYSKEYDOWN=0x104)
    if (wParam = 0x100 || wParam = 0x104) {
        vk := NumGet(lParam, 0, "uint")
        sc := NumGet(lParam, 4, "uint")
        ; E 键: VK=0x00, SC=0x03
        if (vk = 0 && sc = 3) {
            SendInput "^w"
            return 1  ; 拦截此键, 不传递给其他窗口
        }
    }

    return DllCall("CallNextHookEx", "ptr", g_hHook, "int", nCode, "uint", wParam, "ptr", lParam)
}

InstallHook()

; ==================== 消息监测 ====================
OnMessage(0x100, OnMsg)
OnMessage(0x101, OnMsg)
OnMessage(0x104, OnMsg)
OnMessage(0x105, OnMsg)
OnMessage(0x319, OnMsg)
OnMessage(0x00FF, OnMsg)
OnMessage(0x0112, OnMsg)
OnMessage(0x0312, OnMsg)

OnMsg(wParam, lParam, msg, hwnd) {
    static msgNames := Map(
        0x100, "WM_KEYDOWN", 0x101, "WM_KEYUP",
        0x104, "WM_SYSKEYDOWN", 0x105, "WM_SYSKEYUP",
        0x319, "WM_APPCOMMAND",
        0x00FF, "WM_INPUT",
        0x0112, "WM_SYSCOMMAND",
        0x0312, "WM_HOTKEY"
    )
    msgName := msgNames.Get(msg, "0x" Format("{:X}", msg))

    if (msg = 0x319) {
        cmd := (lParam >> 16) & 0x0FFF
        name := appCmdMap.Get(cmd, "Unknown:" cmd)
        txt.Value .= Format("[{}] cmd={} → {}`n", msgName, cmd, name)
    } else if (msg = 0x100 || msg = 0x104) {
        vk := wParam
        sc := (lParam >> 16) & 0x1FF
        keyName := GetKeyName("vk" Format("{:02x}", vk) "sc" Format("{:03x}", sc))
        txt.Value .= Format("[{}] VK=0x{:02X} SC=0x{:03X}  → {}`n", msgName, vk, sc, keyName)
    } else if (msg = 0x00FF) {
        txt.Value .= DecodeRawInput(lParam)
    } else if (msg = 0x0112) {
        txt.Value .= Format("[{}] SysCmd=0x{:X}`n", msgName, wParam & 0xFFF0)
    } else if (msg = 0x0312) {
        txt.Value .= Format("[{}] id=0x{:X}`n", msgName, wParam)
    } else {
        txt.Value .= Format("[{}] wP=0x{:X} lP=0x{:X}`n", msgName, wParam, lParam)
    }
    return 1
}

DecodeRawInput(lParam) {
    static RID_INPUT := 0x10000003
    static typeNames := Map(1, "Mouse", 2, "Keyboard", 3, "HID")
    size := 0
    ret := DllCall("GetRawInputData", "ptr", lParam, "uint", RID_INPUT, "ptr", 0, "uint*", &size, "uint", 8 + A_PtrSize * 2)
    if (ret = 0xFFFFFFFF || size <= 0)
        return Format("[WM_INPUT] GetRawInputData ret={} size={}`n", ret, size)
    buf := Buffer(size)
    ret := DllCall("GetRawInputData", "ptr", lParam, "uint", RID_INPUT, "ptr", buf, "uint*", &size, "uint", 8 + A_PtrSize * 2)
    if (ret = 0xFFFFFFFF)
        return Format("[WM_INPUT] GetRawInputData (2nd) failed ret={}`n", ret)
    type := NumGet(buf, 0, "uint")
    devHandle := NumGet(buf, 8, "ptr")
    typeName := typeNames.Get(type, "Unknown(" type ")")
    result := Format("[WM_INPUT] type={} handle=0x{:p}", typeName, devHandle)

    static RIDI_DEVICENAME := 0x20000007
    nameSize := 0
    DllCall("GetRawInputDeviceInfo", "ptr", devHandle, "uint", RIDI_DEVICENAME, "ptr", 0, "uint*", &nameSize)
    if (nameSize > 0) {
        nameBuf := Buffer(nameSize * 2)
        DllCall("GetRawInputDeviceInfo", "ptr", devHandle, "uint", RIDI_DEVICENAME, "ptr", nameBuf, "uint*", &nameSize)
        SplitPath StrGet(nameBuf, nameSize), &shortName
        result .= " dev=" . shortName
    }

    if (type = 2) {
        kb_offset := 8 + A_PtrSize * 2
        makecode := NumGet(buf, kb_offset, "ushort")
        flags := NumGet(buf, kb_offset + 2, "ushort")
        vk := NumGet(buf, kb_offset + 6, "ushort")
        flagDesc := (flags & 1 ? "BREAK" : "MAKE")
        if (flags & 2) flagDesc .= ",SHIFT"
        if (flags & 4) flagDesc .= ",E0"
        if (flags & 8) flagDesc .= ",E1"
        result .= Format(" VK=0x{:02X} MC=0x{:04X} [{}]", vk, makecode, flagDesc)
    } else if (type = 3) {
        hid_offset := 8 + A_PtrSize * 2
        dwSizeHid := NumGet(buf, hid_offset, "uint")
        dwCount := NumGet(buf, hid_offset + 4, "uint")
        data_offset := hid_offset + 8
        result .= Format(" dwSizeHid={} dwCount={} data=", dwSizeHid, dwCount)
        loop dwSizeHid {
            result .= Format("{:02X}", NumGet(buf, data_offset + A_Index - 1, "uchar"))
        }
    }
    result .= "`n"
    return result
}
