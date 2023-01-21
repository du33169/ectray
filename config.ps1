# -*- coding: utf-8 -*-

Add-Type -AssemblyName System.Windows.Forms

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

$httpPortLabel = New-Object System.Windows.Forms.Label
$httpPortLabel.Text = "HTTP Port:"
$httpPortTextbox = New-Object System.Windows.Forms.TextBox

$accountFileLabel = New-Object System.Windows.Forms.Label
$accountFileLabel.Text = "Account File:"
$accountFileTextbox = New-Object System.Windows.Forms.TextBox

$dnsServerLabel = New-Object System.Windows.Forms.Label
$dnsServerLabel.Text = "DNS Server:"
$dnsServerTextbox = New-Object System.Windows.Forms.TextBox

$tipLabel = New-Object System.Windows.Forms.Label
$tipLabel.Text = "Note: Change will take effect on next launch"
$tipLabel.Size=New-Object System.Drawing.Size(200,30)
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
# Read config.json if it exists
$configFile="config.json"
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

[System.Windows.Forms.Application]::Exit()