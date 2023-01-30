param($version="v0.2.0a18", $folder="${env:USERPROFILE}\AppData\Local\hpcflow")

Function New-TemporaryFolder {
	# Make a new folder based upon a TempFileName
	#$T="$($env:TEMP)\tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	$T="$($env:TMPDIR)/tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	New-Item -ItemType Directory -Path $T
}

$app_name="hpcflow"
$base_link="https://github.com/hpcflow/hpcflow-new/releases/download"

$windows_ending="win-dir"

$progress_string_1="Step 1 of 2: Downloading ${app_name} ..."
$progress_string_2="Step 2 of 2: Installing ${app_name} ..."
$completion_string_1="Installation of ${app_name} complete."

$artifact_name="${app_name}-${version}-${windows_ending}.zip"
$folder_name="${app_name}-${version}-${windows_ending}"
$download_link="${base_link}/${version}/${artifact_name}"

$tempd=New-TemporaryFolder

try{

	Write-Output $progress_string_1

	Invoke-WebRequest $download_link -OutFile $tempd/$artifact_name

	Write-Output $progress_string_2
	if (-Not (Test-Path -Path $folder/$folder_name)) {
		Expand-Archive $tempd/$artifact_name -DestinationPath $tempd
		Move-Item $tempd/$folder_name $folderS
	}

	if(Test-Path -Path $folder/$app_name -PathType Leaf) {
		Remove-Item $folder/$app_name
	}
	New-Item -ItemType SymbolicLink -Path $folder -Name $app_name -value $folder/$folder_name/$folder_name | Out-Null

	Remove-Item $tempd -Recurse
}
catch{
	Write-Host $_
	Remove-Item $tempd -Recurse
}

Write-Output $completion_string_1

