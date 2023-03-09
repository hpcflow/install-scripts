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

	Write-Host 'Test Message'

	if ($OneFile.IsPresent) {
		$ArtifactEnding = '-win.exe'
		$OneFileFlag = $true
	}
	else {
		$ArtifactEnding = '-win-dir.zip'
		$OneFileFlag = $false
	}

	if ($PreRelease.IsPresent) {
		$PreReleaseFlag = $true
	}
	else {
		$PreReleaseFlag = $false
	}

	Get-ScriptParameters | `
	Get-LatestReleaseInfo -PreRelease $PreReleaseFlag | `
	Extract-WindowsInfo -FileEnding $ArtifactEnding | `
	Parse-WindowsInfo | `
	Download-Artifact -DownloadFolder '~/Desktop' | `
	Place-Artifact -FinalDestination $Folder -OneFile $OneFileFlag | `
	Create-SymLinkToApp -Folder $Folder -OneFile $OneFileFlag

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

	if ($Prerelease) {
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

function Download-Artifact {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$ArtifactData,
		[parameter(Mandatory)]
		[string]$DownloadFolder
	)

	$DownloadLocation = $DownloadFolder +"/" + $ArtifactData.ArtifactName

	Write-Host $DownloadLocation

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
	#$T="$($env:TEMP)\tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	$T="$($env:TMPDIR)/tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
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
	}
	else {
		$link_name = $artifact_name.Replace(".zip","")
		New-Item -ItemType SymbolicLink -Path $SymLinkFolder -Name $link_name -Target $Folder/$artifact_name/$artifact_name
	}

	return  $SymLinkFolder

}

function Add-SymLinkFolderToPath {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$SymLinkFolder
	)

	if(-Not (Test-Path $profile)) {
		New-Item -Path $profile -Type File -Force
	}

	 Add-Content $profile "`$env:PATH +=`";$SymLinkFolder`""

}

Install-HPCFlowApplication @PSBoundParameters