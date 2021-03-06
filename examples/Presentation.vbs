Option Explicit
purpose = "Show a notification area icon with a menu option to prevent the computer and monitor from going to sleep."
helpMessage = "When presentation mode is on, the computer and monitor are typically prevented from going into a suspend (sleep) state or hibernation. The computer may still be put to sleep by other applications or by user actions such as closing a laptop lid or pressing a sleep button or power button." & vbLf & vbLf & "Phone charger mode is the same as presentation mode except that the monitor is turned off, initially."
Setup
csTimer.IntervalInHours = .9
icon = Split(icon1, "|")
NormalMode
ListenForCallbacks

Sub NormalMode
    watcher.Watch = False
    notifyIcon.DisableMenuItem normalModeMenuIndex
    notifyIcon.EnableMenuItem presentationModeMenuIndex
    notifyIcon.SetIconByDllFile icon(ico_normFile), icon(ico_normIndex), icon(ico_normType)
    PublishStatus "Normal"
    csTimer.Stop
End Sub
Sub PresentationMode
    watcher.Watch = True
    notifyIcon.EnableMenuItem normalModeMenuIndex
    notifyIcon.DisableMenuItem presentationModeMenuIndex
    notifyIcon.SetIconByDllFile icon(ico_presentFile), icon(ico_presentIndex), icon(ico_presentType)
    PublishStatus "Presentation"
    stopwatch.Reset
    csTimer.Start
End Sub
Sub ChargerMode
    shell.Run "rundll32 user32.dll,LockWorkStation",, synchronous
    WScript.Sleep 1000
    PresentationMode
End Sub
Sub PublishStatus(newStatus)
    status = newStatus
    Dim stream : Set stream = fso.OpenTextFile(statusFile, ForWriting, CreateNew)
    stream.WriteLine newStatus
    stream.Close
    Set stream = Nothing
End Sub
Sub SetDurationUI
    currentValue = Round(csTimer.IntervalInHours, 4)
    prompt = format(Array("Enter the desired duration of Presentation mode / Phone charger mode, in hours.%sCurrent value: %s", vbLf & vbLf, currentValue))
    caption = WScript.ScriptName
    suggestedValue = currentValue
    sa.MinimizeAll
    response = InputBox(prompt, caption, suggestedValue)
    sa.UndoMinimizeAll
    If "" = response Then Exit Sub
    csTimer.IntervalInHours =  response
    If "Presentation" = status Then
        PresentationMode 'reset timers
    End If

    Dim currentValue, response, prompt, caption, suggestedValue
End Sub
Sub Help
    shell.PopUp helpMessage, 80, WScript.ScriptName, vbInformation + vbSystemModal
End Sub
Sub ListenForCallbacks
    While True
        intervalInMinutes = csTimer.Interval/60000
        elapsedMinutes = stopwatch/60
        If "Presentation" = status Then
            notifyIcon.Text = format(Array(" Presentation mode is on %s Normal mode resumes in %s min.", vbLf, Round(intervalInMinutes - elapsedMinutes, 0)))
        Else notifyIcon.Text = "Presentation mode is off"
        End If
        WScript.Sleep 200
    Wend

    Dim elapsedMinutes, intervalInMinutes
End Sub

'icon options
Const icon1 = "%SystemRoot%\System32\powercpl.dll|5|False|%SystemRoot%\System32\powercpl.dll|6|False" 'moon & sun
Const icon2 = "%SystemRoot%\System32\imageres.dll|101|False|%SystemRoot%\System32\imageres.dll|102|False" 'green & yellow shields
Const icon3 = "%SystemRoot%\System32\imageres.dll|96|True|%SystemRoot%\System32\deskmon.dll|0|True" 'monitor with moon & monitor without
Const icon4 = "%SystemRoot%\System32\hgcpl.dll|1|False|%SystemRoot%\System32\hgcpl.dll|0|False" 'dark LED & green LED
Const icon5 = "%SystemRoot%\System32\DDORes.dll|19|False|%SystemRoot%\System32\DDORes.dll|15|False" 'dark flat screen & bright flat screen / small icons
Const icon6 = "%SystemRoot%\System32\DDORes.dll|19|True|%SystemRoot%\System32\DDORes.dll|15|True" 'dark flat screen & bright flat screen / large icons
Const icon7 = "%SystemRoot%\System32\comres.dll|8|False|%SystemRoot%\System32\comres.dll|12|False" 'checkmark on green shield & checkmark on gold shield
Const ico_normFile = 0, ico_normIndex = 1, ico_normType = 2, ico_presentFile = 3, ico_presentIndex = 4, ico_presentType = 5

Const synchronous = True
Const largeIcon = True, smallIcon = False
Const PresentationState = 3, NormalState = 0
Const ForWriting = 2, CreateNew = True
Dim watcher, notifyIcon, shell, fso, csTimer, sa, stopwatch, includer, format 'objects
Dim normalModeMenuIndex, presentationModeMenuIndex 'integer corresponding to current status
Dim purpose, helpUrl, helpMessage 'strings
Dim statusFile 'filespec of file to which status is published
Dim status 'string: '"Presentation" or "Normal"
Dim icon '4-element array: filespec and index for Presentation and Normal modes

Sub Setup
    Set shell = CreateObject("WScript.Shell")
    Dim dataFolder : dataFolder = shell.ExpandEnvironmentStrings("%AppData%\VBScripting")
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(dataFolder) Then fso.CreateFolder dataFolder
    Set format = CreateObject("VBScripting.StringFormatter")
    statusFile = format(Array("%s\%s.status", dataFolder, fso.GetBaseName(WScript.ScriptName)))

    Set notifyIcon = CreateObject("VBScripting.NotifyIcon")
    notifyIcon.AddMenuItem "Normal mode", GetRef("NormalMode")
        normalModeMenuIndex = 0
    notifyIcon.AddMenuItem "Presentation mode", GetRef("PresentationMode")
        presentationModeMenuIndex = 1
    notifyIcon.AddMenuItem "Phone charger mode", GetRef("ChargerMode")
    notifyIcon.AddMenuItem "Set duration", GetRef("SetDurationUI")
    notifyIcon.AddMenuItem "Help", GetRef("Help")
    notifyIcon.AddMenuItem "Exit " & WScript.ScriptName, GetRef("CloseAndExit")
    notifyIcon.Visible = True

    Set csTimer = CreateObject("VBScripting.Timer")
    csTimer.AutoReset = False
    Set csTimer.Callback = GetRef("NormalMode")

    Set watcher = CreateObject("VBScripting.Watcher")
    Set sa = CreateObject("Shell.Application")
    Set includer = CreateObject("VBScripting.Includer")
    Execute includer.Read("VBSStopwatch")
    Set stopwatch = New VBSStopwatch
End Sub
Sub CloseAndExit
    PublishStatus "Normal"
    watcher.Dispose
    Set watcher = Nothing
    notifyIcon.Dispose
    Set notifyIcon = Nothing
    csTimer.Dispose
    Set csTimer = Nothing
    Set shell = Nothing
    Set fso = Nothing
    Set sa = Nothing
    Set includer = Nothing
    Set stopwatch = Nothing
    Set format = Nothing
    WScript.Quit
End Sub
