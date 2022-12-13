#!/bin/bash

source install_dir.txt

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        download_link="${base_link}/${latest_version}/${app_name}-${latest_version}-${linux_ending}"
        echo "linux"
        echo $download_link
elif [[ "$OSTYPE" == "darwin"* ]]; then
        artifact_name="${app_name}-${latest_version}-${macOS_ending}"
        download_link="${base_link}/${latest_version}/${artifact_name}"
        echo "macOS"
        wget $download_link
        unzip $artifact_name
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        echo "cygwin"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        echo "msys"
elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
        echo "win32"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "freebsd"
else
        echo "no idea"
fi