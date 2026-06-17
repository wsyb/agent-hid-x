#!/usr/bin/python3
"""
按键检测器 - GTK 窗口，实时显示所有按键

使用方法：
  systemctl --user stop xremap     # 必须先停 xremap，否则收不到事件
  /usr/bin/python3 key_detector.py
  # 按完要测的键后关掉窗口，然后：
  systemctl --user start xremap

输出格式：
  设备名                            code=NNNN  按键名称
  记录 code=NNNN，在 config.yml 中用 Code_NNN 格式编写映射
"""
import evdev, os, select, threading, gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

TARGET_DEVICES = []

# 搜索设备
for p in sorted(os.listdir('/dev/input')):
    if not p.startswith('event'): continue
    try:
        d = evdev.InputDevice(f'/dev/input/{p}')
    except: continue
    name = d.name
    # 排除无关设备
    if any(x in name for x in ['HDA', 'HDMI', 'Intel', 'Mic', 'Line', 'Headphone', 'Sleep', 'Power', 'xremap', 'remote-mapper', 'mouse-mapper']):
        d.close()
        continue
    if any(x in name for x in ['XING WEI', 'Telink', 'INSTANT USB', 'USB PnP Audio', '小米', '语音', 'Keyboard', 'Mouse', 'Consumer', 'System Control', 'Composite']):
        TARGET_DEVICES.append((d.path, name))
    d.close()

# GTK 窗口
class KeyDetector(Gtk.Window):
    def __init__(self):
        super().__init__(title="按键检测器")
        self.set_default_size(700, 500)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_keep_above(True)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        vbox.set_margin_top(10)
        vbox.set_margin_bottom(10)
        vbox.set_margin_start(10)
        vbox.set_margin_end(10)

        label = Gtk.Label(label="请按你要检测的按键，信息会显示在下方。\n按 Ctrl+C 或关闭窗口退出。")
        vbox.pack_start(label, False, False, 0)

        self.textview = Gtk.TextView()
        self.textview.set_editable(False)
        self.textview.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.textbuffer = self.textview.get_buffer()
        
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.add(self.textview)
        vbox.pack_start(scrolled, True, True, 0)

        btn_box = Gtk.Box(spacing=6)
        clear_btn = Gtk.Button(label="清空")
        clear_btn.connect("clicked", self.on_clear)
        btn_box.pack_end(clear_btn, False, False, 0)
        vbox.pack_start(btn_box, False, False, 0)

        self.add(vbox)
        self.show_all()

        # 启动监听线程
        self.running = True
        thread = threading.Thread(target=self.listen_loop, daemon=True)
        thread.start()

    def on_clear(self, btn):
        self.textbuffer.set_text("")

    def add_text(self, text):
        GLib.idle_add(self._append_text, text)

    def _append_text(self, text):
        end = self.textbuffer.get_end_iter()
        self.textbuffer.insert(end, text)
        # 滚动到底部
        mark = self.textbuffer.create_mark(None, self.textbuffer.get_end_iter(), False)
        self.textview.scroll_to_mark(mark, 0.0, False, 0.0, 0.0)

    def listen_loop(self):
        devices = []
        for path, name in TARGET_DEVICES:
            try:
                d = evdev.InputDevice(path)
                devices.append(d)
            except Exception as ex:
                print(f"无法打开 {path}: {ex}", file=sys.stderr)

        self.add_text(f"共 {len(devices)} 个设备\n")
        self.add_text("请按任意键...\n" + "-" * 60 + "\n")

        while self.running:
            try:
                r, _, _ = select.select(devices, [], [], 0.5)
                for d in r:
                    for ev in d.read():
                        if ev.type == 1 and ev.value == 1:
                            name = evdev.ecodes.KEY.get(ev.code, f'UNKNOWN{ev.code}')
                            self.add_text(f"  {d.name:35s}  code={ev.code:4d}  {name}\n")
            except Exception as ex:
                print(f"select 错误: {ex}", file=sys.stderr)
                break

        for d in devices:
            try: d.close()
            except: pass

    def on_destroy(self, widget):
        self.running = False

if __name__ == '__main__':
    app = KeyDetector()
    app.connect("destroy", lambda w: Gtk.main_quit())
    Gtk.main()
