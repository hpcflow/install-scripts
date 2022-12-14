#!/bin/bash

linux_install_dir="~/.local/share/hpcflow"
macOS_install_dir="~/Library/Application\ Support/hpcflow"
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
        echo "Downloading hpcflow ..."
        curl -s $download_link -O -L
        echo "Installing hpcflow ..."
	unzip -qq $artifact_name
        mkdir $linux_install_dir
        mv dist/onedir/$artifact_name $linux_install_dir
elif [[ "$OSTYPE" == "darwin"* ]]; then
        artifact_name="${app_name}-${latest_version}-${macOS_ending}"
        download_link="${base_link}/${latest_version}/${artifact_name}"
        echo "Downloading hpcflow ..."
        curl -s $download_link -O -L
        echo "Installing hpcflow ..."
        unzip -qq $artifact_name
        mkdir $macOS_install_dir
        mv dist/onedir/$artifact_name $macOS_install_dir
else
        echo "Operating system ${OSTYPE} not supported."
fi