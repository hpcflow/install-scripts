# install-folder-version

This repository contains scripts to install the pyinstaller folder version of 
hpcflow on a local machine running macOS or linux (through a bash or zsh 
terminal), or windows (through a powershell terminal).

By default the latest version is downloaded and placed in a suitable user
specific folder. A particular version and install folder can be specified too.
The user is provided with a prompt to add the install folder to their path to 
enable them to run hpcflow.

To install in macOS or linux, enter the following command in a terminal window:
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.sh)"`

To set options, use:
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.sh --version version-value --folder folder-value)"`

For windows, enter the following command in a powershell window:
`iex (iwr 'https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.ps1').Content`

To set options, use:
`& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.ps1'))) -version version-value -folder folder-value`
