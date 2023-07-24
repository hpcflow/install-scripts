param(
	[Parameter()]
	[string]$Folder,

	[Parameter()]
	[switch]$OneFile,

	[Parameter()]
	[switch]$PreRelease

)

function Install-MatFlowApplication {

	param(
		[Parameter()]
		[string]$Folder,

		[Parameter()]
		[switch]$OneFile,

		[Parameter()]
		[switch]$PreRelease
	)
	#trap{
		# Check if DownloadFolder variable has been created. If it has, delete folder it points to.

		# First check variable exists (i.e. is not null)
		#if($DownloadFolder){
			# Next check if folder exists
		#	if(Test-Path -Path $DownloadFolder){
		#		Remove-Item $DownloadFolder
		#		}
		#}
		#Write-Host "Installation of" $AppName "unsuccessful"
		#Exit
		#Return
	#}

	$AppName = "matflow"

	if ($OneFile.IsPresent) {
		$ArtifactEnding = '-win.exe'
		$OneFileFlag = $true
		$AppType = "single file"
	}
	else {
		$ArtifactEnding = '-win-dir.zip'
		$OneFileFlag = $false
		$AppType = "single folder"
	}

	if ($PreRelease.IsPresent) {
		$PreReleaseFlag = $true
		$VersionType = "latest prerelease"
	}
	else {
		$PreReleaseFlag = $false
		$VersionType = "latest stable"
	}


	Write-Host "Installing $AppName $VersionType $AppType version..."
	Start-Sleep -Milliseconds 100

	if ($PSBoundParameters.ContainsKey('Folder')) {
		Write-Host "Installing to user specified folder $Folder..."
		Start-Sleep -Milliseconds 100
	}
	else {
		$Folder = Get-InstallDir
		Write-Host "Installing to default location $Folder..."
		Start-Sleep -Milliseconds 100
	}

	$DownloadFolder = New-TemporaryFolder

	Get-ScriptParameters | `
	Get-LatestReleaseInfo -PreRelease $PreReleaseFlag | `
	Extract-WindowsInfo -FileEnding $ArtifactEnding | `
	Parse-WindowsInfo | `
	Check-AppInstall -Folder $Folder -OneFile $OneFileFlag | `
	Download-Artifact -DownloadFolder $DownloadFolder | `
	Place-Artifact -FinalDestination $Folder -OneFile $OneFileFlag | `
	Create-SymLinkToApp -Folder $Folder -OneFile $OneFileFlag | `
	Add-SymLinkFolderToPath

	

}

function Get-InstallDir {
	$WindowsInstallDir = "${env:USERPROFILE}\AppData\Local\matflow"

	return $WindowsInstallDir
}

function  Get-ScriptParameters {
    $params = @{
        AppName = "matflow"
        BaseLink = "https://github.com/hpcflow/matflow-new/releases/download"
        WindowsEndingFolder ="win-dir"
	    WindowsEndingFile = "win.exe"
        WindowsInstallDir = "${env:USERPROFILE}\AppData\Local\matflow"

	    LatestStableReleases = "https://raw.githubusercontent.com/hpcflow/matflow-new/dummy-stable/docs/source/released_binaries.yml"
	    LatestPrereleaseReleases="https://raw.githubusercontent.com/hpcflow/matflow-new/develop/docs/source/released_binaries.yml"

	    ProgressString1="Step 1 of 2: Downloading $AppName ..."
	    ProgressString2="Step 2 of 2: Installing $AppName ..."
	    CompletionString1="Installation of $AppName complete."
    }

    return $params
}

function Get-LatestReleaseInfo {
	param(
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$param,
		[Parameter()]
		[bool]$PreRelease
	)

	if ($PreRelease) {
		$PageHTML = Invoke-WebRequest -Uri $param.LatestPrereleaseReleases -Method Get
	}
	else {
		$PageHTML = Invoke-WebRequest -Uri $param.LatestStableReleases -Method Get
	}
	
	$PageContents = $PageHTML.Content

	return $PageContents

}

function Extract-WindowsInfo {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$PageContents,
		[parameter(Mandatory)]
		[string]$FileEnding
	)

	$StablePageContentsSplit = $PageContents -Split "\n"

	foreach ($VersionInfo in $StablePageContentsSplit) {
		if ($VersionInfo -Like "*"+$FileEnding) {
			return $VersionInfo
		}
	}
}

function Parse-WindowsInfo {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$VersionInfo
	)

	$Parts = $VersionInfo -Split ': '
	$ArtifactData = @{
		ArtifactName = $Parts[0]
		ArtifactWebAddress = $Parts[1]
	}

	return $ArtifactData

}

function Check-AppInstall {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$ArtifactData,
		[parameter(Mandatory)]
		[string]$Folder,
		[parameter(Mandatory)]
		[bool]$OneFile
	)

	if($OneFile) {
		$FileToCheck = $Folder + '/' +$ArtifactData.ArtifactName
		if(Test-Path $FileToCheck) {
			Write-Host "This version already installed..."
			Start-Sleep -Milliseconds 50
			Write-Host "Exiting..."
			Start-Sleep -Milliseconds 100
			#Exit
			Return
		}
	}
	Else {
		$FileToCheck = $Folder + '/'+$ArtifactData.ArtifactName.Replace(".zip",'')
		if(Test-Path -PathType container $FileToCheck) {
			Write-Host "This version already installed..."
			Start-Sleep -Milliseconds 50
			Write-Host "Exiting..."
			Start-Sleep -Milliseconds 100
			#Exit
			Return
		}
	}

	Return $ArtifactData

}

function Download-Artifact {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$ArtifactData,
		[parameter(Mandatory)]
		[string]$DownloadFolder
	)

	Write-Host "Downloading "$ArtifactData.ArtifactName
	Start-Sleep -Milliseconds 100
	Write-Host $DownloadFolder

	$DownloadLocation = $DownloadFolder +"/" + $ArtifactData.ArtifactName

	Invoke-WebRequest $ArtifactData.ArtifactWebAddress -OutFile $DownloadLocation

	$ArtifactData = $ArtifactData + @{DownloadLocation=$DownloadLocation}

	return $ArtifactData

}

function Place-Artifact {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$ArtifactData,
		[parameter(Mandatory)]
		[string]$FinalDestination,
		[parameter()]
		[bool]$OneFile
	)

	if ($OneFile) {
		Move-Item $ArtifactData.DownloadLocation $FinalDestination
	}
	else {
		Expand-Archive $ArtifactData.DownloadLocation -DestinationPath $FinalDestination
		Remove-Item $ArtifactData.DownloadLocation
	}

	$ArtifactData = $ArtifactData + @{FinalDesination=$FinalDesination}

	Return $ArtifactData

}

function New-TemporaryFolder {
	# Make a new folder based upon a TempFileName
	$T="$($env:TEMP)\tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	#$T="$($env:TMPDIR)/tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	New-Item -ItemType Directory -Path $T
}

function Create-SymLinkToApp {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$ArtifactData,

		[parameter(Mandatory)]
		[string]$Folder,

		[parameter()]
		[bool]$OneFile
	)

	$artifact_name = $ArtifactData.ArtifactName

	$AliasFolderExists = Test-Path -PathType container $Folder\aliases
	Write-Host "Alias folder exists: $AliasFolderExists"

	if(-Not (Test-Path -PathType container $Folder\aliases))
	{
		Write-Host $Folder\aliases
		New-Item -ItemType Directory -Path $Folder\aliases
		$AliasFolderExists = Test-Path -PathType container $Folder\aliases
		Write-Host "Alias folder exists: $AliasFolderExists"

	}

	# First create folder to store alias files if it doesn't exist

	$AliasFile=$Folder+"\aliases\matflow_aliases.csv"

	if (-Not (Test-Path $AliasFile -PathType leaf)) {
		New-Item -Force -Path $AliasFile -Type File
	}

	if($OneFile) {
		
		if (-Not (Get-Content $AliasFile | %{$_ -match $artifact_name})) {
			Add-Content $AliasFile "`"$artifact_name`",`"$Folder\$artifact_name`",`"`",`"None`""
		}
		
		Write-Host "Type $artifact_name to get started!"
		Start-Sleep -Milliseconds 100

	}
	else {

		$link_name = $artifact_name.Replace(".zip","")
		$folder_name = $link_name
		$exe_name = $artifact_name.Replace(".zip",".exe")
		
		if (-Not (Get-Content $AliasFile | %{$_ -match $link_name})) {
			Add-Content $AliasFile "`"$link_name`",`"$Folder\$folder_name\$exe_name`",`"`",`"None`""
		}
		Write-Host "Type $link_name to get started!"
		Start-Sleep -Milliseconds 100
	}


	return  $AliasFile

}

function Add-SymLinkFolderToPath {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$AliasFile
	)

	if(-Not (Test-Path $profile)) {
		New-Item -Path $profile -Type File
	}

	$ImportString = "Import-Alias $AliasFile" 

	if (-Not (Get-Content $profile | %{$_ -match $ImportString.replace('\','\\')})) {
		Add-Content $profile $ImportString
		& $profile
	}

}

Install-MatFlowApplication @PSBoundParameters
