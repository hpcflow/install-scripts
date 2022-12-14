#!/bin/bash

linux_install_dir="~/.local/share/hpcflow"
macOS_install_dir="~/Library/Application Support/hpcflow"
windows_install_dir="%USERPROFILE%\AppData\Local\hpcflow"
app_name="hpcflow"
base_link="https://github.com/hpcflow/hpcflow-new/releases/download"
latest_version="v0.2.0a18"
linux_ending="linux-dir.zip"
macOS_ending="macOS-dir.zip"
windows_ending="windows-dir.zip"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        artifact_name="${app_name}-${latest_version}-${linux_ending}"
        download_link="${base_link}/${latest_version}/${artifact_name}"
        echo "linux"
        curl $download_link -O -L
	unzip $artifact_name
elif [[ "$OSTYPE" == "darwin"* ]]; then
        artifact_name="${app_name}-${latest_version}-${macOS_ending}"
        download_link="${base_link}/${latest_version}/${artifact_name}"
        echo "macOS"
        curl $download_link -O -L
        unzip $artifact_name
else
        echo "Operating system ${OSTYPE} not supported."
fi
