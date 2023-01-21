Add-Type -AssemblyName System.Windows.Forms
# 获取当前脚本所在目录
$currentDirectory = $PSScriptRoot
echo $currentDirectory
# 获取当前系统桌面路径
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutFile="$desktop\PodmanEasyConnect.lnk"
if(Test-Path $shortcutFile){
	Remove-Item -Path $shortcutFile -Force
}
# 创建快捷方式
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutFile)
$shortcut.TargetPath = "powershell"
$shortcut.Arguments = " -File ${currentDirectory}\systray.ps1"
$shortcut.WorkingDirectory = "$currentDirectory"
$shortcut.WindowStyle = 7 #minimized
$shortcut.IconLocation = "${currentDirectory}\ec_on.ico"
$shortcut.Save()
