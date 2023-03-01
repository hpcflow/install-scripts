function  Get-Script-Parameters {
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

function Get-Latest-Stable-Release-Info {
	param(
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[hashtable]$param,

		[Parameter()]
		[bool]$PrereleaseFlag
	)

	if ($PrereleaseFlag) {
		$PageHTML = Invoke-WebRequest -Uri $param.LatestPrereleaseReleases -Method Get
	}
	else {
		$PageHTML = Invoke-WebRequest -Uri $param.LatestStableReleases -Method Get
	}
	
	$PageContents = $PageHTML.Content

	return $PageContents

}

function Extract-Windows-Info {
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

function Parse-Windows-Info {
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

function New-TemporaryFolder {
	# Make a new folder based upon a TempFileName
	#$T="$($env:TEMP)\tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	$T="$($env:TMPDIR)/tmp$([convert]::tostring((get-random 65535),16).padleft(4,'0')).tmp"
	New-Item -ItemType Directory -Path $T
}