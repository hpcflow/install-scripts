#!/bin/bash

app_name="hpcflow"
base_link="https://github.com/hpcflow/hpcflow-new/releases/download"

linux_ending="linux-dir"
macOS_ending="macOS-dir"
linux_install_dir=~/.local/share/hpcflow
macOS_install_dir=~/Library/Application\ Support/hpcflow

latest_version="v0.2.0a18"

progress_string_1="Step 1 of 2: Downloading ${app_name} ..."
progress_string_2="Step 2 of 2: Installing ${app_name} ..."
completion_string_1="Installation of ${app_name} complete."

# Make temp diretory and store path in a variable
TEMPD=$(mktemp -d)

# Exit if temp directory wasn't created successfully
if [ ! -r "$TEMPD" ]; then
	>&2 echo "Failed to create temp directory for download"
	exit 1
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then


        folder=${folder:-${linux_install_dir}}
        version=${version:-${latest_version}}

        while [ $# -gt 0 ]; do

                if [[ $1 == *"--"* ]]; then
                        param="${1/--/}"
                        declare $param="$2"
                        echo $1 $2 // Optional to see the parameter:value result
                fi

                shift

        done

        artifact_name="${app_name}-${version}-${linux_ending}.zip"
        folder_name="${app_name}-${version}-${linux_ending}"
        download_link="${base_link}/${version}/${artifact_name}"

elif [[ "$OSTYPE" == "darwin"* ]]; then

        folder=${folder:-${macOS_install_dir}}
        version=${version:-${latest_version}}

        while [ $# -gt 0 ]; do

                if [[ $1 == *"--"* ]]; then
                        param="${1/--/}"
                        declare $param="$2"
                        echo $1 $2 // Optional to see the parameter:value result
                fi

                shift

        done

        artifact_name="${app_name}-${version}-${macOS_ending}.zip"
        folder_name="${app_name}-${version}-${macOS_ending}"
        download_link="${base_link}/${version}/${artifact_name}"

else
        echo "Operating system ${OSTYPE} not supported."
fi

echo $progress_string_1
curl -s --output-dir $TEMPD $download_link -O -L
echo $progress_string_2
unzip -qq $TEMPD/$artifact_name -d $TEMPD
chmod -R u+rw $TEMPD/dist/onedir/$folder_name
mkdir -p "${folder}"
mv -n $TEMPD/dist/onedir/$folder_name "${folder}"
ln -s "${folder}/"${folder_name}/"${folder_name} "${folder}/hpcflow
echo $completion_string_1
sleep 0.2
echo "Add "${folder}" to path by adding:"
echo "export PATH=\"\$PATH:"${folder}/${folder_name}"\""
echo "to ~/.bashrc or ~/.zshrc ."

# Make sure temp directory is deleted on exit
trap "exit 1"		HUP INT PIPE QUIT TERM
trap 'rm -rf $TEMPD'	EXIT
