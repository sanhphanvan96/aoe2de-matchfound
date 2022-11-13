#include <GuiConstants.au3>
#include <Misc.au3>
#include <SendMessage.au3>

;#NoTrayIcon
Opt("GUICloseOnESC", 0)
Opt("GUIOnEventMode", 1)
Opt("WinWaitDelay", 0)

;Global $WM_SYSCOMMAND = 0x0112
Global $SC_MOVE = 0xF010
Global $SC_SIZE = 0xF000
Global $SC_CLOSE = 0xF060

;ShellHook notification codes:
Global $HSHELL_WINDOWCREATED = 1;
Global $HSHELL_WINDOWDESTROYED = 2;
Global $HSHELL_ACTIVATESHELLWINDOW = 3;
Global $HSHELL_WINDOWACTIVATED = 4;
Global $HSHELL_GETMINRECT = 5;
Global $HSHELL_REDRAW = 6;
Global $HSHELL_TASKMAN = 7;
Global $HSHELL_LANGUAGE = 8;
Global $HSHELL_SYSMENU = 9;
Global $HSHELL_ENDTASK = 10;
Global $HSHELL_ACCESSIBILITYSTATE = 11;
Global $HSHELL_APPCOMMAND = 12;
Global $HSHELL_WINDOWREPLACED = 13;
Global $HSHELL_WINDOWREPLACING = 14;
Global $HSHELL_RUDEAPPACTIVATED = 32772;
Global $HSHELL_FLASH = 32774;

Global $bHook = 1

;GUI stuff:
Global $iGuiW = 400, $iGuiH = 50, $sTitle = "AOE2 DE Match Found", $aBtnText[2] = ["START", "STOP"]
$hGui = GUICreate($sTitle, $iGuiW, $iGuiH, -1, 0, $WS_POPUP+$WS_BORDER, $WS_EX_TOPMOST)
GUISetOnEvent($GUI_EVENT_CLOSE, "SysEvents")
GUISetOnEvent($GUI_EVENT_PRIMARYDOWN, "SysEvents")
GUIRegisterMsg($WM_SYSCOMMAND, "On_WM_SYSCOMMAND")
$cBtnMini = GUICtrlCreateButton("–", $iGuiW-$iGuiH, 0, $iGuiH/2, $iGuiH/2)
GUICtrlSetOnEvent(-1, "CtrlEvents")
GUICtrlSetTip(-1, "Minimize")
$cBtnClose = GUICtrlCreateButton("X", $iGuiW-$iGuiH/2, 0, $iGuiH/2, $iGuiH/2)
GUICtrlSetOnEvent(-1, "CtrlEvents")
GUICtrlSetTip(-1, "Exit")
$cBtnHook = GUICtrlCreateButton("", $iGuiW-$iGuiH, $iGuiH/2, $iGuiH, $iGuiH/2)
GUICtrlSetData(-1, $aBtnText[$bHook])
GUICtrlSetTip(-1, "Start/Stop Listener")
GUICtrlSetOnEvent(-1, "CtrlEvents")
$cList = GUICtrlCreateList("", 0, 0, $iGuiW-$iGuiH-1, $iGuiH, $LBS_NOINTEGRALHEIGHT+$WS_VSCROLL)
GUICtrlSetOnEvent(-1, "CtrlEvents")
;GUIDE

MsgPrint("Press Ctrl + Click to drag GUI")
;Hook stuff:
GUIRegisterMsg(RegisterWindowMessage("SHELLHOOK"), "HShellWndProc")
ShellHookWindow($hGui, $bHook)

GUISetState(@SW_SHOWMINIMIZED)

While 1
    Sleep(1000)
WEnd

Func SysEvents()
    Switch @GUI_CtrlId
        Case $GUI_EVENT_CLOSE
            Exit
        Case $GUI_EVENT_PRIMARYDOWN
            ;CTRL + Left click to drag GUI
            If _IsPressed("11") Then
                DllCall("user32.dll", "int", "ReleaseCapture")
                DllCall("user32.dll", "int", "SendMessage", "hWnd", $hGui, "int", 0xA1, "int", 2, "int", 0)
            EndIf
    EndSwitch
EndFunc

Func CtrlEvents()
    Switch @GUI_CtrlId
        Case $cBtnMini
            GUISetState(@SW_MINIMIZE)
        Case $cBtnClose
            _SendMessage($hGui, $WM_SYSCOMMAND, $SC_CLOSE, 0)
        Case $cBtnHook
            $bHook = BitXOR($bHook, 1)
            ShellHookWindow($hGui, $bHook)
            GUICtrlSetData($cBtnHook, $aBtnText[$bHook])
    EndSwitch
EndFunc

Func HShellWndProc($hWnd, $Msg, $wParam, $lParam)
    If $wParam = $HSHELL_FLASH Then
	  $title = WinGetTitle($lParam)
	  ConsoleWrite($title)
	  MsgPrint("> Window flashing: " & " (" &$title & ")")
	  If $title = "Age Of Empires II: Definitive Edition" Then
		 SoundPlay(@ScriptDir & "\14.wav", 1)
		 Sleep(2000)
	  EndIf
    EndIf
EndFunc

;register/unregister ShellHook
Func ShellHookWindow($hWnd, $bFlag)
    Local $sFunc = 'DeregisterShellHookWindow'
    If $bFlag Then
	   $sFunc = 'RegisterShellHookWindow'
	   MsgPrint('> Waiting for a match')
    Else
	   MsgPrint('> Alert has been disabled')
    EndIf
    Local $aRet = DllCall('user32.dll', 'int', $sFunc, 'hwnd', $hWnd)
    ;MsgPrint($sFunc & ' = ' & $aRet[0])
    Return $aRet[0]
EndFunc

Func MsgPrint($sText)
    ConsoleWrite($sText & @CRLF)
    GUICtrlSendMsg($cList, $LB_SETCURSEL, GUICtrlSendMsg($cList, $LB_ADDSTRING, 0, $sText), 0)
EndFunc

;register window message
Func RegisterWindowMessage($sText)
    Local $aRet = DllCall('user32.dll', 'int', 'RegisterWindowMessage', 'str', $sText)
    Return $aRet[0]
EndFunc

Func On_WM_SYSCOMMAND($hWnd, $Msg, $wParam, $lParam)
    Switch BitAND($wParam, 0xFFF0)
        Case $SC_MOVE, $SC_SIZE
        Case $SC_CLOSE
            ShellHookWindow($hGui, 0)
            Return $GUI_RUNDEFMSG
    EndSwitch
EndFunc
