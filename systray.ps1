param($arg1)
if(-not($arg1 -eq 'debug')){# if not with debug than start a new process to hide window
	$myPath=$MyInvocation.MyCommand.Path
	Write-Host $myPath
	Start-Process -FilePath "powershell" -ArgumentList "-File $myPath debug" -WindowStyle Hidden
	exit
}

Add-Type -AssemblyName System.Windows.Forms
$title="Podman EasyConnect"
# Create NotifyIcon object
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = "./ec_off.ico"
$notifyIcon.Visible = $true

$configFile="config.json"
$podoutFile="podout.txt"
$containerName="ec_container"

function edit_config($wait=$true){
	if($wait){
		Start-Process -FilePath "powershell" -ArgumentList '-File config.ps1' -NoNewWindow -Wait
	}else{
		Start-Process -FilePath "powershell" -ArgumentList '-File config.ps1' -NoNewWindow
	}
	
}
function read_config{
	Write-Host "try read config"
	while(-not (Test-Path $configFile)) {
		edit_config
	}
	return Get-Content config.json | ConvertFrom-Json
}
function ec_start {
	Write-Host "try start ec"
	try{
		$config=read_config

		$SOCKS5_PORT=$config.sockPort
		$HTTP_PORT=$config.httpPort
		$configFile=$config.accountFile
		$dnsServer=$config.dnsServer

		$successPattern="login successfully"

		Clear-Content $podoutFile
		$prcHandle = Start-Process -FilePath 'podman'	-ArgumentList "run",`
		"--name $containerName --replace --rm --device /dev/net/tun --cap-add NET_ADMIN",`
		"--dns $dnsServer -p ${SOCKS5_PORT}:1080 -p ${HTTP_PORT}:8888",`
		"-e EC_VER=7.6.3 -v ${configFile}:/root/.easyconn",`
		"-e CLI_OPTS=`" -d rvpn.zju.edu.cn`"",`
		"hagb/docker-easyconnect:cli" `
		-RedirectStandardOutput $podoutFile -RedirectStandardError $podoutFile -PassThru -WorkingDirectory $PsScriptRoot -WindowStyle Hidden
	}catch {
		# Write-Error $_
		$msgResult=[System.Windows.Forms.MessageBox]::Show("Start podman failed.`n`n$_",$title,"OK","Error")
		return $false
	}
	$prcPid=$prcHandle.Id
	Write-Host "process started with pid:${prcPid}"
	# wait until successPattern appear
	#Get-Content $podoutFile -Wait -Tail 1 | Select-String -Pattern $successPattern | Select-Object -First 1
	$timeout = 5 #sec
	$success = $false

	$sw = [diagnostics.stopwatch]::StartNew()
	while(($sw.elapsed.seconds -lt $timeout) -and (-not $prcHandle.hasExited)){ # 如果程序异常退出或者超时则失败
			$fileContent=(Get-Content $podoutFile -Raw)
			# Write-Host $fileContent
			if($fileContent -match $successPattern){
					$success = $true
					break
			}
			Start-Sleep -Milliseconds 100
	}
	if($success){
		Write-Host "Podman EasyConnect started successfully"
		$notifyIcon.ShowBalloonTip(5000, $title, "Started Successfully", [System.Windows.Forms.ToolTipIcon]::Info)
		return $true
	}
	else{
		$fileContent=(Get-Content $podoutFile -Raw)
		if (-not $prcHandle.hasExited) {
			Stop-Process -Id $prcPid
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Easyconnect login failed.`nLog:`n$fileContent",$title,"OK","Error")
		}
		else{
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Podman process aborted.`nLog:`n$fileContent",$title,"OK","Error")
		}
		return $false
	}
}

function ec_stop{
	Write-Host "try stop ec"
	# stop container
	podman stop $containerName
	if($LASTEXITCODE -eq 0){
		$notifyIcon.ShowBalloonTip(5000, "Podman EasyConnect", "Stopped Successfully", [System.Windows.Forms.ToolTipIcon]::Info)
		return $true
	}
	else{
		$msgResult=[System.Windows.Forms.MessageBox]::Show("Failed to stop.`nExit Code: $LASTEXITCODE","Podman EasyConnect","OK","Error")
		return $false
	}
}
# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenu
$enableItem = New-Object System.Windows.Forms.MenuItem
$enableItem.Text = "Enable"
$enableItem.Checked = $false
$enableItem.Add_Click({
	if ($enableItem.Checked) {
		# ->disable
		$success=ec_stop
		Write-Host "stop result: $success"
		if($success){
			$enableItem.Checked = $false
			$notifyIcon.Icon = "./ec_off.ico"
		}

	} else {
		# ->enable
		$success=ec_start
		Write-Host "start result: $success"
		if($success){
			$enableItem.Checked = $true
			$notifyIcon.Icon = "./ec_on.ico"
		}
	}
})

#setting
$settingItem = New-Object System.Windows.Forms.MenuItem
$settingItem.Text = "Settings"
$settingItem.Add_Click({
	edit_config($wait=$false)
})

#exit
$exitItem = New-Object System.Windows.Forms.MenuItem
$exitItem.Text = "Exit"
$exitItem.Add_Click({
	$notifyIcon.Visible = $false
	[System.Windows.Forms.Application]::Exit()
})
$contextMenu.MenuItems.AddRange(@($enableItem,$settingItem,$exitItem))

$notifyIcon.ContextMenu = $contextMenu

# Run the application
[System.Windows.Forms.Application]::Run()
