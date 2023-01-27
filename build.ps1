$src=".\ectray.ps1"
$icon="./ec_on.ico"
$attachFiles="README.md","ec_on.ico","ec_off.ico"

$date = (Get-Date).ToString("yyyyMMdd")
$packageDir="build/ectray"
$buildTarget="$packageDir/ectray.exe"
$releaseDir="release"
$zippedTarget = "$releaseDir/ectray_$date.zip"

if(-not (Test-Path $packageDir)){
	Write-Host "creating packageDir $packageDir"
	New-Item -ItemType Directory -Path $packageDir | Out-Null
}
Write-Host "compiling with ps2exe..."
Invoke-ps2exe $src $buildTarget -noConsole -noOutput -iconFile $icon
if(-not (Test-Path $buildTarget)){
    Write-Host "build failed, no target file"
	exit 1
}
else{
	Write-Host "target generated: $buildTarget"
}

Write-Host "packaging..."

foreach($item in $attachFiles){
    if (Test-Path $item) {
        Copy-Item -Recurse -Force -Path $item -Destination $packageDir
    }
}

Write-Host "compressing..."
if(-not (Test-Path $releaseDir)){ # create releaseDir
	Write-Host "creating releaseDir $releaseDir"
    New-Item -ItemType Directory -Path $releaseDir | Out-Null  
}
Compress-Archive -Force -Path $packageDir -DestinationPath $zippedTarget
if(-not (Test-Path $zippedTarget)){ # test compress output
    Write-Host "compress failed"
	exit 1
}
else{
	Write-Host "compressed to $zippedTarget"
}
Write-Host "done"