Option Explicit
Dim fso, scriptDir, cmd, shell
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
cmd = "cmd.exe /c """ & scriptDir & "\start_record_if_after_time.bat"""
Set shell = CreateObject("WScript.Shell")
shell.Run cmd, 0, False
