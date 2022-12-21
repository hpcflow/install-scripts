param($version="v0.2.0a18", $folder="${env:USERPROFILE}\AppData\Local\hpcflow")

$app_name="hpcflow"
$base_link="https://github.com/hpcflow/hpcflow-new/releases/download"

$windows_ending="win-dir"

$progress_string_1="Step 1 of 2: Downloading ${app_name} ..."
$progress_string_2="Step 2 of 2: Installing ${app_name} ..."
$completion_string_1="Installation of ${app_name} complete."

$artifact_name="${app_name}-${version}-${windows_ending}.zip"
$folder_name="${app_name}-${version}-${windows_ending}"
$download_link="${base_link}/${version}/${artifact_name}"

Write-Output $latest_version
Write-Output $version

Write-Output $progress_string_1
Invoke-WebRequest $download_link -OutFile $artifact_name

Write-Output $progress_string_2
Expand-Archive $artifact_name -DestinationPath ./
Move-Item $folder_name $folder

Write-Output $completion_string_1

