#Requires AutoHotkey v2.0

; Dims every monitor with an always-on-top window showing a message. The windows
; catch all mouse clicks; a double-click on any of them calls OnUnlock.
class Overlay {
    static WM_LBUTTONDBLCLK := 0x203

    __New(text := "CatKey locked", opacity := 77) {
        this.Text := text
        this.Opacity := opacity
        this.OnUnlock := ""
        this._guis := []
        this._onDblClick := ObjBindMethod(this, "_HandleDblClick")
    }

    IsShown => this._guis.Length > 0

    Hwnds {
        get {
            hwnds := []
            for g in this._guis
                hwnds.Push(g.Hwnd)
            return hwnds
        }
    }

    Show() {
        if this.IsShown
            return
        OnMessage(Overlay.WM_LBUTTONDBLCLK, this._onDblClick)
        Loop MonitorGetCount() {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            w := right - left, h := bottom - top
            ; -DPIScale: MonitorGet returns physical pixels, so size the window in pixels too
            g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
            g.BackColor := "000000"
            g.SetFont("s48 cWhite", "Segoe UI")
            g.AddText("x0 y" (h // 2 - 60) " w" w " h120 Center BackgroundTrans", this.Text)
            g.Show("x" left " y" top " w" w " h" h " NA")
            WinSetTransparent(this.Opacity, "ahk_id " g.Hwnd)
            this._guis.Push(g)
        }
        this._TakeFocus()
    }

    Hide() {
        OnMessage(Overlay.WM_LBUTTONDBLCLK, this._onDblClick, 0)
        if !this.IsShown
            return
        for g in this._guis
            g.Destroy()
        this._guis := []
    }

    KeepOnTop() {
        for g in this._guis
            WinSetAlwaysOnTop(1, "ahk_id " g.Hwnd)
        this._TakeFocus()
    }

    ; Keystrokes from a non-elevated hook can't be swallowed for an elevated
    ; foreground window, and the wheel goes to the focused window, so the
    ; overlay keeps focus while shown.
    _TakeFocus() {
        if this.IsShown && !WinActive("ahk_id " this._guis[1].Hwnd)
            WinActivate("ahk_id " this._guis[1].Hwnd)
    }

    _HandleDblClick(wParam, lParam, msg, hwnd) {
        ; Clicks on the text control land on the window itself (static controls
        ; are click-transparent), but check the root window to be safe.
        root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
        for g in this._guis {
            if (g.Hwnd = root) {
                if this.OnUnlock
                    SetTimer(this.OnUnlock, -1)
                return 0
            }
        }
    }
}
