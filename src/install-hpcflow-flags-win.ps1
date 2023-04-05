param(
	[Parameter()]
	[string]$Folder,

	[Parameter()]
	[switch]$OneFile,

	[Parameter()]
	[switch]$PreRelease

)

function Install-HPCFlowApplication {

	param(
		[Parameter()]
		[string]$Folder,

		[Parameter()]
		[switch]$OneFile,

		[Parameter()]
		[switch]$PreRelease
	)
	trap{
		# Check if DownloadFolder variable has been created. If it has, delete folder it points to.

		# First check variable exists (i.e. is not null)
		if($DownloadFolder){
			# Next check if folder exists
			if(Test-Path -Path $DownloadFolder){
				Remove-Item $DownloadFolder
				}
		}
		Write-Host "Installation of" $AppName "unsuccessful"
		#Exit
	}

	$AppName = "hpcflow"

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
	$WindowsInstallDir = "${env:USERPROFILE}\AppData\Local\hpcflow"
	#$WindowsInstallDir = "/Users/user/Documents/hpcflow_test"

	return $WindowsInstallDir
}

function  Get-ScriptParameters {
    $params = @{
        AppName = "hpcflow"
        BaseLink = "https://github.com/hpcflow/hpcflow-new/releases/download"
        WindowsEndingFolder ="win-dir"
	    WindowsEndingFile = "win.exe"
        WindowsInstallDir = "${env:USERPROFILE}\AppData\Local\hpcflow"

	    LatestStableReleases = "https://raw.githubusercontent.com/hpcflow/hpcflow-new/dummy-stable/docs/source/released_binaries.yml"
	    LatestPrereleaseReleases="https://raw.githubusercontent.com/hpcflow/hpcflow-new/develop/docs/source/released_binaries.yml"

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
		[string]$StablePageContents,
		[parameter(Mandatory)]
		[string]$FileEnding
	)

	$StablePageContentsSplit = $StablePageContents -Split [System.Environment]::NewLine

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
			Exit
		}
	}
	Else {
		$FileToCheck = $Folder + '/'+$ArtifactData.ArtifactName.Replace(".zip",'')
		if(Test-Path -PathType container $FileToCheck) {
			Write-Host "This version already installed..."
			Start-Sleep -Milliseconds 50
			Write-Host "Exiting..."
			Start-Sleep -Milliseconds 100
			Exit
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

	if(-Not (Test-Path -PathType container $Folder/links))
	{
		New-Item -ItemType Directory -Path $Folder/links
	}

	# First create links folder if it doesn't exist

	$SymLinkFolder=$Folder+"/links"

	if($OneFile) {
		New-Item -ItemType SymbolicLink -Path $SymLinkFolder -Name $artifact_name -Target $Folder/$artifact_name
		Write-Host "Type $artifact_name to get started!"
		Start-Sleep -Milliseconds 100
	}
	else {
		$link_name = $artifact_name.Replace(".zip","")
		New-Item -ItemType SymbolicLink -Path $SymLinkFolder -Name $link_name -Target $Folder/$artifact_name/$artifact_name
		Write-Host "Type $link_name to get started!"
		Start-Sleep -Milliseconds 100
	}


	return  $SymLinkFolder

}

function Add-SymLinkFolderToPath {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$SymLinkFolder
	)

	if(-Not ($Env:Path -split ";" -contains $SymLinkFolder)) {

		if(-Not (Test-Path $profile)) {
			New-Item -Path $profile -Type File
		}

	 	Add-Content $profile "`$env:PATH +=`";$SymLinkFolder`""
		& $profile

	}

}

Install-HPCFlowApplication @PSBoundParameters
