#!/bin/bash

app_name="hpcflow"
base_link="https://github.com/hpcflow/hpcflow-new/releases/download"

linux_ending="linux-dir"
macOS_ending="macOS-dir"
linux_install_dir=~/.local/share/hpcflow
macOS_install_dir=~/Library/Application\ Support/hpcflow

latest_stable_version="v0.0.1"
latest_prerelease_version="v0.2.0a19"

latest_stable_releases="https://raw.githubusercontent.com/hpcflow/hpcflow-new/main/docs/source/released_binaries.yml"
latest_prelease_releases="https://raw.githubusercontent.com/hpcflow/hpcflow-new/develop/docs/source/released_binaries.yml"

progress_string_1="Step 1 of 2: Downloading ${app_name} ..."
progress_string_2="Step 2 of 2: Installing ${app_name} ..."
completion_string_1="Installation of ${app_name} complete."

# Flag variables false by default
prerelease=false
purge=false
path=false

# Flag to note if user specified version
versionspec=false

# Make temp diretory and store path in a variable
TEMPD=$(mktemp -d)

# Exit if temp directory wasn't created successfully
if [ ! -r "$TEMPD" ]; then
	>&2 echo "Failed to create temp directory for download"
	exit 1
fi

# Assign command line variables and flags
while [ $# -gt 0 ]; do

    if [[ $1 == *"--"* ]]; then

        param="${1/--/}"

        if [[ "$param" == "prerelease" ]] || [[ $param == "purge" ]] || [[ $param == "path" ]]; then
            declare $param=true
        else
            declare $param="$2"
			if [[ "$param" == "version "]]; then
				versionspec == true
			fi

        fi

        # echo $1 $2 // Optional to see the parameter:value result

    fi

    shift

done

# Set OS specific variables
if [[ "$OSTYPE" == "linux-gnu"* ]]; then

        folder=${folder:-${linux_install_dir}}
        
elif [[ "$OSTYPE" == "darwin"* ]]; then

        folder=${folder:-${macOS_install_dir}}

else
        echo "Operating system ${OSTYPE} not supported."
fi

# If prelease flag is set, default is latest prerelease, otherwise latest stable
# Both overridden if version specified by user
if [ "$prerelease" = true ]; then

	echo "Installing latest prelease version"
	sleep 0.2
    version=${version:-${latest_prerelease_version}}

else

	echo "Installing latest stable version"
	sleep 0.2
    version=${version:-${latest_stable_version}}

fi

# Set variables for download and install
artifact_name="${app_name}-${version}-${macOS_ending}.zip"
folder_name="${app_name}-${version}-${macOS_ending}"
download_link="${base_link}/${version}/${artifact_name}"

if [ "$purge" != true ]; then

	echo $progress_string_1
	echo
	curl -s --output-dir $TEMPD $download_link -O -L
	echo $progress_string_2
	echo
	unzip -qq $TEMPD/$artifact_name -d $TEMPD
	chmod -R u+rw $TEMPD/dist/onedir/$folder_name
	mkdir -p "${folder}"
	mv -n $TEMPD/dist/onedir/$folder_name "${folder}"

	# Create symlinks and clear up older versions
	if [[ "$prerelease" != true ]] && [[ "$versionspec" != true ]]; then

		# Default - pre-release or specific version not specified
		#
		# Create generic app_name sym link to latest release along with specific version numbered link


		ln -s "${folder}/${folder_name}/${folder_name}" "${folder}/links/${app_name}"
		ln -s "${folder}/${folder_name}/${folder_name}" "${folder}/links/${folder_name}"

		echo "-no -name ${folder_name}" >> stable_versions.txt

		tail -n3 stable_versions.txt >> to_keep.txt
		mv to_keep.txt stable_versions.txt

		# Delete symlinks and folders not stored in 
		find "${folder}/links/${app_name}-v*" `cat stable_versions.txt` -delete
		find "${folder}/${app_name}-v*" `cat stable_versions.txt` -delete

		# Record sym link names to inform user

		symstring="${app_name} or ${folder_name}$"

	else

		ln -s "${folder}/${folder_name}/${folder_name}" "${folder}/links/${folder_name}"

		# Record sym link names to inform user

		symstring=${folder_name}

	fi

	if [ "$path" = true ]; then

		# Check if folders on path already
		case :$PATH: in
			*:"${folder}":)	echo "${folder} on path already." ;;
			*) "${folder} not on path ... adding."
		esac

		# Check which files exist
		if test -f ~/.zshrc; then
			echo "Updating ~/.zshrc..."
			echo "export PATH=\"\$PATH:"${folder}"\"" >> ~/.zshrc
		fi

		if test -f ~/.bashrc; then
			echo "Updating ~/.bashrc...";
			echo "export PATH=\"\$PATH:"${folder}"\"" >> ~/.bashhrc
		fi
	fi

	echo $completion_string_1
	sleep 0.2
	if [ "$path" != true ]; then
		echo
		echo
		echo "Add "${app_name}" to path by adding the following line to ~/.bashrc or ~/.zshrc:"
		echo "export PATH=\"\$PATH:"${folder}"\""
	fi
	echo
	echo
	echo "Type ${symstring} to get started."

elif [ "$purge" = true ]; then
	
	echo "Purging local install of "${app_name}"..."
	sleep 0.2
	echo "I say we take off and nuke the entire site from orbit. It's the only way to be sure."
	# echo "Deleting "${app_name}" folder "${folder}"..."
	# sleep 0.2
	#rm -r  "${folder}"
	# echo "Removing "${app_name}" folder "$folder}" from path..."
	# sleep 0.2
	# COMMAND GOES HERE

fi

# Make sure temp directory is deleted on exit
trap "exit 1"		HUP INT PIPE QUIT TERM
trap 'rm -rf $TEMPD'	EXIT
