param($arg1)
if(($arg1 -eq 'quiet')){# if not with debug than start a new process to hide window
	$myPath=$MyInvocation.MyCommand.Path
	Write-Host $myPath
	Start-Process -FilePath "powershell" -ArgumentList "-File $myPath" -WindowStyle Hidden
	exit
}

# get current path
if (($MyInvocation.MyCommand.CommandType) -eq "ExternalScript"){ 
	$ScriptPath = ( Split-Path -Parent -Path $MyInvocation.MyCommand.Definition )
}else{ 
	$ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0]) 
	if (!$ScriptPath){ $ScriptPath = "." } 
}

Write-Host ($ScriptPath)

Add-Type -AssemblyName System.Windows.Forms
$title="Podman EasyConnect"
$configFile="config.json"
$podoutFile="podout.txt"
$poderrFile="poderr.txt"
$containerName="ec_container"

# init_notifyIcon >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	# Create NotifyIcon object
	$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
	$notifyIcon.Icon = "./ec_off.ico"
	$notifyIcon.Visible = $true
	# Create context menu
	$contextMenu = New-Object System.Windows.Forms.ContextMenu
	$enableItem = New-Object System.Windows.Forms.MenuItem
	$enableItem.Text = "Enable"
	$enableItem.Checked = $false
	#setting
	$settingItem = New-Object System.Windows.Forms.MenuItem
	$settingItem.Text = "Settings"
	#exit
	$exitItem = New-Object System.Windows.Forms.MenuItem
	$exitItem.Text = "Exit"

	$contextMenu.MenuItems.AddRange(@($enableItem,$settingItem,$exitItem))
	$notifyIcon.ContextMenu = $contextMenu
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# check podman machine state & podman installation
$machineState=(((podman machine info) -match "MachineState: (.*)") -split ":"|Select-Object -Index 1).trim()
if($machineState -eq "Running"){
	Write-Host "machine Running"
}
elseif($machineState -eq "Stopped"){
	Write-Host "machine not running, starting..."
	podman machine start
	if($? -and ($LASTEXITCODE -eq 0)){
		Write-Host "successfully started podman machine"
		$notifyIcon.ShowBalloonTip(2000, $title, "Podman machine started", [System.Windows.Forms.ToolTipIcon]::Info)
	}
	else{
		$msgResult=[System.Windows.Forms.MessageBox]::Show("Start podman machine failed.",$title,"OK","Error")
		exit 1
	}
}
else{
	$msgResult=[System.Windows.Forms.MessageBox]::Show("Failed to get podman machine state.`nCheck your podman installation",$title,"OK","Error")
	exit 1
}
#init setting form>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	#create Form
	$form = New-Object System.Windows.Forms.Form
	$form.Text = "Podman EasyConnect Settings"
	$form.Icon = "./ec_on.ico"
	$form.Size = New-Object System.Drawing.Size(250,230)
	$form.StartPosition = "CenterScreen"
	$form.FormBorderStyle = "FixedSingle"
	$form.TopMost=$true; $form.MinimizeBox = $false; $form.MaximizeBox = $false
	$form.Padding = New-Object System.Windows.Forms.Padding(10,10,10,10)

	#flowLayout
	$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
	$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
	$flowLayoutPanel.AutoSize = $true
	$form.Controls.Add($flowLayoutPanel)

	#add data
	$sockPortLabel = New-Object System.Windows.Forms.Label
	$sockPortLabel.Text = "SOCKS5 Port:"
	$sockPortTextbox = New-Object System.Windows.Forms.TextBox
	$sockPortTextbox.MaxLength = 4
	$sockPortTextbox.Add_TextChanged({
	if(-not ($sockPortTextbox.Text -match '^[0-9]{0,4}$')){
		$sockPortTextbox.Text = $sockPortTextbox.Text -replace '[^0-9]',''
	}})
	$httpPortLabel = New-Object System.Windows.Forms.Label
	$httpPortLabel.Text = "HTTP Port:"
	$httpPortTextbox = New-Object System.Windows.Forms.TextBox
	$httpPortTextbox.MaxLength = 4
	$httpPortTextbox.Add_TextChanged({
	if(-not ($httpPortTextbox.Text -match '^[0-9]{0,4}$')){
		$httpPortTextbox.Text = $httpPortTextbox.Text -replace '[^0-9]',''
	}})
	$accountFileLabel = New-Object System.Windows.Forms.Label
	$accountFileLabel.Text = "Account File:"
	$accountFileTextbox = New-Object System.Windows.Forms.TextBox

	$dnsServerLabel = New-Object System.Windows.Forms.Label
	$dnsServerLabel.Text = "DNS Server:"
	$dnsServerTextbox = New-Object System.Windows.Forms.TextBox

	$tipLabel = New-Object System.Windows.Forms.Label
	$tipLabel.Text = "Note: Change will take effect on next launch"
	$tipLabel.Size=New-Object System.Drawing.Size(230,30)
	# Create OK and Cancel buttons
	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Text = "OK"
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Text = "Cancel"
	$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

	# Add controls to the form
	$flowLayoutPanel.Controls.AddRange(@($sockPortLabel,$sockPortTextbox,$httpPortLabel,$httpPortTextbox,$accountFileLabel,$accountFileTextbox, $dnsServerLabel, $dnsServerTextbox,$okButton, $cancelButton, $tipLabel))
	# label middleLeft
	foreach ($label in $flowLayoutPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] }) { $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft }
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

function edit_config($wait=$true){
	Write-Host "edit config"
	# if($wait -eq $false){
	# 	Start-Job -ScriptBlock {edit_config($true)}
	# }else{
		Write-Host "block mode"
		if(Test-Path $configFile) {
			$config = Get-Content $configFile | ConvertFrom-Json
			$sockportTextbox.Text = $config.sockPort
			$httpPortTextbox.Text = $config.httpPort
			$accountFileTextbox.Text = $config.accountFile
			$dnsServerTextbox.Text = $config.dnsServer
		}
		else {
			# Set default values
			$sockportTextbox.Text = "2080"
			$httpPortTextbox.Text = "9898"
			$accountFileTextbox.Text = "./.easyconn"
			$dnsServerTextbox.Text = "114.114.114.114"
		}

		# Show the form and get the result
		$result = $form.ShowDialog()

		if($result -eq [System.Windows.Forms.DialogResult]::OK) {
			# Save the input to config.json
			$config = @{
				sockPort = $sockportTextbox.Text
				httpPort = $httpPortTextbox.Text
				accountFile = $accountFileTextbox.Text
				dnsServer = $dnsServerTextbox.Text
			}
			$config | ConvertTo-Json | Set-Content $configFile
		}
	# }
}
function read_config{
	Write-Host "read config"
	while(-not (Test-Path $configFile)) {
		edit_config
	}
	return Get-Content $configFile | ConvertFrom-Json
}
function ec_start {
	Write-Host "start ec"
	try{
		$config=read_config

		$SOCKS5_PORT=$config.sockPort
		$HTTP_PORT=$config.httpPort
		$accountFile=$config.accountFile
		$dnsServer=$config.dnsServer

		$successPattern="login successfully"

		if(-not (Test-Path $accountFile)){# account file not existed
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Account File `"$accountFile`" not found.`nPlease run once manually with option `"-v ${accountFile}:/root/.easyconn`"",$title,"OK","Error")
			return $false
		}
		else{
			Clear-Content $podoutFile
			Clear-Content $poderrFile
			$prcHandle = Start-Process -FilePath 'podman'	-ArgumentList "run",`
			"--name $containerName --replace --rm --device /dev/net/tun --cap-add NET_ADMIN",`
			"--dns $dnsServer -p ${SOCKS5_PORT}:1080 -p ${HTTP_PORT}:8888",`
			"-e EC_VER=7.6.3 -v ${accountFile}:/root/.easyconn",`
			"hagb/docker-easyconnect:cli" `
			-RedirectStandardOutput $podoutFile -RedirectStandardError $poderrFile -PassThru -WorkingDirectory $ScriptPath -WindowStyle Hidden
		}
	}catch {
		# Write-Error $_
		$msgResult=[System.Windows.Forms.MessageBox]::Show("Start podman failed.`n`n$_",$title,"OK","Error")
		return $false
	}
	$success = $false
	$prcPid=$prcHandle.Id
	if($prcPid){# else success=$false
		Write-Host "process started with pid:${prcPid}"
		# wait until successPattern appear
		#Get-Content $podoutFile -Wait -Tail 1 | Select-String -Pattern $successPattern | Select-Object -First 1
		$timeout = 5 #sec
		$sw = [diagnostics.stopwatch]::StartNew()
		while(($sw.elapsed.seconds -lt $timeout) -and (-not $prcHandle.hasExited)){ # ?????????????????????????????????????????????
				$fileContent=(Get-Content $podoutFile -Raw)
				# Write-Host $fileContent
				if($fileContent -match $successPattern){
						$success = $true
						break
				}
				Start-Sleep -Milliseconds 100
		}
	}
	if($success){
		Write-Host "Podman EasyConnect started successfully"
		$notifyIcon.ShowBalloonTip(5000, $title, "Started Successfully", [System.Windows.Forms.ToolTipIcon]::Info)
		return $true
	}
	else{
		$fileContent=(Get-Content $podoutFile -Raw)
		$errContent=(Get-Content $poderrFile -Raw)
		if(-not $prcPid){
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Cannot start podman process",$title,"OK","Error")
		}elseif (-not $prcHandle.hasExited) {
			Stop-Process -Id $prcPid
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Easyconnect login failed.`nLog:`n$errContent",$title,"OK","Error")
		}else{
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Podman process aborted.`nLog:`n$errContent",$title,"OK","Error")
		}
		return $false
	}
}

function ec_stop{
	Write-Host "stop ec"
	# stop container
	podman stop $containerName
	if($? -and ($LASTEXITCODE -eq 0)){
		$notifyIcon.ShowBalloonTip(5000, "Podman EasyConnect", "Stopped Successfully", [System.Windows.Forms.ToolTipIcon]::Info)
		return $true
	}
	else{
		$msgResult=[System.Windows.Forms.MessageBox]::Show("Failed to stop.`nExit Code: $LASTEXITCODE","Podman EasyConnect","OK","Error")
		return $false
	}
}

# add menu Item action
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
$settingItem.Add_Click({
	edit_config($wait=$false)
})
$exitItem.Add_Click({
	if($enableItem.Checked){
		ec_stop
	}
	if($machineState -eq "Stopped"){# only stop the self-started machine (keep the machine state the same as before)
		Write-Host "stopping podman machine"
		podman machine stop 
		if($LASTEXITCODE -eq 0){
			$notifyIcon.ShowBalloonTip(2000, $title, "Podman machine stopped", [System.Windows.Forms.ToolTipIcon]::Info)
		}else{
			$msgResult=[System.Windows.Forms.MessageBox]::Show("Failed to stop podman machine.",$title,"OK","Error")
		}
	}
	$notifyIcon.Visible = $false
	[System.Windows.Forms.Application]::Exit()
})
# Run the application
[System.Windows.Forms.Application]::Run() # blocking
