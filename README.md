# install-scripts

Scripts to install the pyinstaller packaged versions of HPCFlow and MatFlow. There are four scripts:
- `install-hpcflow.sh`: Install HPCFlow on a system running a UNIX based OS using BASH or ZSHRC (Linux or MacOS).
- `install-hpcflow.ps1`: Install HPCFlow on a system running Windows using Powershell.
- `install-matflow.sh`: Install MatFlow on a system running a UNIX based OS using BASH or ZSHRC (Linux or MacOS).
- `install-matflow.ps1`: Install MatFlow on a system running Windows using Powershell.

Currently the UNIX verison of the installer is more fully featured than the Windows version.

## Default behaviour

Without any parameters or flags specified the script behaves, it's behaviour is as follows.

1. The latest stable release of the application in the "one folder" format is downloaded as a zip archive to a 
temporary folder. 

2. The zip archive is extracted to a default installation folder. The installation folder depends on the OS.

3. A symbolic link (Linux/macOS) or an alias (Windows) is created.

### Windows only 

### Linux/macOS only

### Default install locations

## Parameters and flags

The behaviour of the scripts can be configures using a series of parameters and flags. These are summarised below for 
the two types of script. 

### Linux/MacOS

#### Parameters

- `--folder=FOLDER`: Specify the folder that the application will be installed to. Should be the absolute path.
- `--version=VERSION`: Specify the version of the application that will be installed. Must be an official release.

#### Flags

- `--prerelease`: Specify that the latest pre-release version is installed.
- `--purge`: Delete all installed versions of the application.
- `--path`: Add the symlink folder to the path by adding a line to the end of `~/.bashrc` or `~/.zshrc`.
- `--onefile`: Specify that the "one file" version should be installed.
- `--univlink`: Specify that the symlink created has a universal rather than a versioned name.


### Windows

#### Parameters

- `-Folder FOLDER`: Specify the folder that the application will be installed to. Should be the absolute path.

#### Flags

- `-OneFile`: Specify that the "one file" version should be installed.
- `-PreRelease` Specify that the latest pre-release version should be installed.

## Using the scripts

### Copy from remote and execute locally

### Clone the repository


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
`curl -sSL https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.sh | folder=folder-var version=version-var bash`

For windows, enter the following command in a powershell window:
`iex (iwr 'https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.ps1').Content`

To set options, use:
`& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/hpcflow/install-folder-version/main/install-hpcflow.ps1'))) -version version-value -folder folder-value`
