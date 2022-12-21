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
