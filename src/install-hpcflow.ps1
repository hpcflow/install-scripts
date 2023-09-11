param(
	[Parameter()]
	[string]$Folder,

	[Parameter()]
	[string]$Version,

	[Parameter()]
	[switch]$OneFile,

	[Parameter()]
	[switch]$PreRelease,

	[Parameter()]
	[switch]$UnivLink

)

function Install-Application {

	param(
		[Parameter()]
		[string]$Folder,

		[Parameter()]
		[string]$Version,

		[Parameter()]
		[switch]$OneFile,

		[Parameter()]
		[switch]$PreRelease,

		[Parameter()]
		[switch]$UnivLink

	)
	Trap{
		# Check if DownloadFolder variable has been created. If it has, delete folder it points to.

		# First check variable exists (i.e. is not null)
		#if($DownloadFolder){
			# Next check if folder exists
		#	if(Test-Path -Path $DownloadFolder){
		#		Remove-Item $DownloadFolder
		#		}
		#}

		Write-Output "Installation of" $AppName "unsuccessful. $_"
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

	if( $UnivLink.IsPresent) {
		$UnivLinkFlag = $true
	}
	else {
		$UnivLinkFlag = $true
	}


	Write-Host "Installing $AppName $VersionType $AppType version..."
	Start-Sleep -Milliseconds 100

	if ($PSBoundParameters.ContainsKey('Folder')) {
		Write-Host "Installing to user specified folder $Folder..."
		Start-Sleep -Milliseconds 100
	}
	else {
		$Folder = Get-InstallDir -AppName $AppName
		Write-Host "Installing to default location $Folder..."
		Start-Sleep -Milliseconds 100
	}

	if ($PSBoundParameters.ContainsKey('Version')) {
		$VersionSpecFlag = $true
	}
	else {
		$VersionSpecFlag = $false
		$Version = "latest"
	}

	$ScriptDataFilenames = @{
		AppName=$AppName
		Folder=$Folder
		UserVersions=$Folder+"\user_versions.txt"
		StableVersions=$Folder+"\stable_versions.txt"
		PreReleaseVersions=$Folder+"\prerelease_versions.txt"
		AliasFile=$Folder+"\aliases\aliases.csv"
	}

	Check-InstallDir -Folder $Folder
	Check-InstallTrackerFiles -ScriptDataFilenames $ScriptDataFilenames

	$DownloadFolder = New-TemporaryFolder

	$param = Get-ScriptParameters -AppName $AppName 

	Get-ScriptParameters -AppName $AppName | `
	Get-LatestReleaseInfo -PreRelease $PreReleaseFlag | `
	Extract-WindowsInfo -FileEnding $ArtifactEnding | `
	Parse-WindowsInfo -VersionSpec $VersionSpecFlag -Version $Version -param $param| `
	Check-AppInstall -Folder $Folder -OneFile $OneFileFlag | `
	Download-Artifact -DownloadFolder $DownloadFolder | `
	Place-Artifact -FinalDestination $Folder -OneFile $OneFileFlag | `
	Create-SymLinkToApp -OneFile $OneFileFlag -PreRelease $PreReleaseFlag -UnivLink $UnivLinkFlag -ScriptDataFilenames $ScriptDataFilenames| `
	 
	Add-SymLinkFolderToPath

}

function Get-InstallDir {

	param(
		[Parameter()]
		[string]$AppName
	)

	$WindowsInstallDir = "${env:USERPROFILE}\AppData\Local\$AppName"

	return $WindowsInstallDir
}

function Check-InstallDir {

	param(
		[Parameter()]
		[string]$Folder
	)

	if(-Not (Test-Path $Folder)) {
		$null = New-Item -Force -ItemType Directory $Folder
	}

}

function Check-InstallTrackerFiles {

	param(
		[Parameter()]
		[hashtable]$ScriptDataFilenames
	)

	$UserVersions=$ScriptDataFilenames.UserVersions
	$StableVersions=$ScriptDataFilenames.StableVersions
	$PreReleaseVersions=$ScriptDataFilenames.PreReleaseVersions

	if(-Not (Test-Path $UserVersions)) {
		$null = New-Item -Force -ItemType File $UserVersions 
	}

	if(-Not (Test-Path $StableVersions)) {
		$null = New-Item -Force -ItemType File $StableVersions
	}

	if(-Not (Test-Path $PreReleaseVersions)) {
		$null = New-Item -Force -ItemType File $PreReleaseVersions
	}

}

function  Get-ScriptParameters {

	param(
		[Parameter()]
		[string]$AppName
	)

    $params = @{
        AppName = $AppName
        BaseLink = "https://github.com/hpcflow/$AppName-new/releases/download"
        WindowsEndingFolder ="win-dir"
	    WindowsEndingFile = "win.exe"
        WindowsInstallDir = "${env:USERPROFILE}\AppData\Local\$AppName"

	    LatestStableReleases = "https://raw.githubusercontent.com/hpcflow/$AppName-new/dummy-stable/docs/source/released_binaries.yml"
	    LatestPrereleaseReleases="https://raw.githubusercontent.com/hpcflow/$AppName-new/develop/docs/source/released_binaries.yml"

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
		$PageHTML = Invoke-WebRequest -UseBasicParsing -Uri $param.LatestPrereleaseReleases -Method Get
	}
	else {
		$PageHTML = Invoke-WebRequest -UseBasicParsing -Uri $param.LatestStableReleases -Method Get
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
		[string]$VersionInfo,
		[parameter()]
		[bool]$VersionSpec,
		[parameter()]
		[string]$Version,
		[parameter()]
		[hashtable]$param
	)

	if ($VersionSpec) {

		$Name = $param['AppName'] +"-" +$Version +"-" +$param['WindowsEndingFile']
		$WebAddress = $param['BaseLink'] +"/" +$Version +"/" +$Name

		$ArtifactData = @{
			ArtifactName = $Name
			ArtifactWebAddress = $WebAddress
		}

	}
	else {
		$Parts = $VersionInfo -Split ': '
		$ArtifactData = @{
			ArtifactName = $Parts[0]
			ArtifactWebAddress = $Parts[1]
		}
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

	$DownloadLocation = $DownloadFolder +"/" + $ArtifactData.ArtifactName

	Invoke-WebRequest -UseBasicParsing $ArtifactData.ArtifactWebAddress -OutFile $DownloadLocation

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
	New-Item -Force -ItemType Directory -Path $T
}

function Create-SymLinkToApp {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$ArtifactData,

		[parameter()]
		[bool]$OneFile,

		[parameter()]
		[bool]$PreReleaseFlag,

		[parameter()]
		[bool]$VersionSpecFlag,

		[parameter()]
		[bool]$UnivLink,

		[parameter()]
		[hashtable]$ScriptDataFilenames


	)

	$UserVersions=$ScriptDataFilenames.UserVersions
	$StableVersions=$ScriptDataFilenames.StableVersions
	$PreReleaseVersions=$ScriptDataFilenames.PreReleaseVersions
	$Folder=$ScriptDataFilenames.Folder
	$AppName=$ScriptDataFilenames.AppName

	$artifact_name = $ArtifactData.ArtifactName

	if(-Not (Test-Path -PathType container $Folder\aliases))
	{
		$null = New-Item -Force -ItemType Directory -Path $Folder\aliases
	}

	# First create folder to store alias files if it doesn't exist

	$AliasFile=$Folder+"\aliases\aliases.csv"

	if (-Not (Test-Path $AliasFile -PathType leaf)) {
		$null = New-Item -Force -Path $AliasFile -Type File
	}

	if($OneFile) {
		
		if (-Not (Get-Content $AliasFile | %{$_ -match $artifact_name})) {
			Add-Content $AliasFile "`"$artifact_name`",`"$Folder\$artifact_name`",`"`",`"None`""
		}

		if($UnivLink) {
			if($PreReleaseFlag) {
				$univ_link_name = "$AppName-dev"
			}
			else {
				$univ_link_name = "$AppName"
			}
			Add-Content $AliasFile "`"$univ_link_name`",`"$Folder\$artifact_name`",`"`",`"None`""
		}

		
		Write-Host "Type $artifact_name to get started!"
		Start-Sleep -Milliseconds 100

		if($VersionSpecFlag) {
			Add-Content $UserVersions "$Folder\$artifact_name"
		}
		elseif($PreReleaseFlag){
			Add-Content $PreReleaseVersions "$Folder\$artifact_name"
		}
		else{
			Add-Content $StableVersions "$Folder\$artifact_name"
		}


	}
	else {

		$link_name = $artifact_name.Replace(".zip","")
		$folder_name = $link_name
		$exe_name = $artifact_name.Replace(".zip",".exe")
		
		if (-Not (Get-Content $AliasFile | %{$_ -match $link_name})) {
			Add-Content $AliasFile "`"$link_name`",`"$Folder\$folder_name\$exe_name`",`"`",`"None`""
		}

		if($UnivLink) {
			if($PreRelease) {
				$univ_link_name = "$AppName-dev"
			}
			else {
				$univ_link_name = "$AppName"
			}
			Add-Content $AliasFile "`"$univ_link_name`",`"$Folder\$folder_name\$exe_name`",`"`",`"None`""
		}

		if($VersionSpecFlag) {
			Add-Content $UserVersions "$Folder\$folder_name\$exe_name"
		}
		elseif($PreReleaseFlag){
			Add-Content $PreReleaseVersions "$Folder\$folder_name\$exe_name"
		}
		else{
			Add-Content $StableVersions "$Folder\$folder_name\$exe_name"
		}

		Write-Host "Type $link_name to get started!"
		Start-Sleep -Milliseconds 100
	}

	Prune-InstalledVersions -ScriptDataFilenames $ScriptDataFilenames


	return  $AliasFile

}

function Prune-InstalledVersions {
	param(
		[parameter(Mandatory)]
		[hashtable]$ScriptDataFilenames
	)
	Trap {
		Write-Output "HI THERE!"
	}


	RUBBISH!

	Get-Content -tail 3 $ScriptDataFilenames.UserVersions > temp.txt
	Move-Item -Force temp.txt $ScriptDataFilenames.UserVersions

	Get-Content -tail 3 $ScriptDataFilenames.PreReleaseVersions > temp.txt
	Move-Item -Force temp.txt $ScriptDataFilenames.PreReleaseVersions

	Get-Content -tail 3 $ScriptDataFilenames.StableVersions > temp.txt
	Move-Item -Force temp.txt $ScriptDataFilenames.StableVersions

	$ToKeepWildCard = $ScriptDataFilenames.Folder +"\\*_versions.txt"

	$to_keep=Get-Content $ToKeepWildCard

	$AppWildCard = $ScriptDataFilenames.AppName+"*"

	Get-ChildItem $AppWildCard -Path $ScriptDataFilenames.Folder | Where-Object { $to_keep -notcontains $_.name } |`
	Remove-Item -whatif

}

function Add-SymLinkFolderToPath {
	param(
		[parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$AliasFile
	)

	if(-Not (Test-Path $profile)) {
		$null = New-Item -Force -Path $profile -Type File
	}

	$ImportString = "Import-Alias $AliasFile" 

	if (-Not (Get-Content $profile | %{$_ -match $ImportString.replace('\','\\')})) {
		Add-Content $profile $ImportString
		& $profile
	}

}

Trap{'Oh dear!'}
Install-Application @PSBoundParameters
