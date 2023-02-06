#!/bin/bash
run_main() {

	set_variables

	set_flags

	make_tempdir

	parse_params "$@"

	set_OS_specific_variables

	get_artifact_names

	touch "${folder}"/user_versions.txt
	touch "${folder}"/stable_versions.txt

	if [ $(grep -c "${version}-{app_name_ending}" "${folder}"/user_versions.txt) -ge 1 ] || [ $(grep -c "${version}-{app_name_ending}" "${folder}"/stable_versions.txt) -ge 1 ]; then

		echo "${app_name} ${version} already installed on this system... "
		sleep 0.2
		echo "Exiting..."
		exit 1

	fi

	# Check if folders on path already
	case :$PATH: in
	*:"${folder}"/links:) onpath=true ;;
	*) ;;
	esac

	# Set variables for download and install
	folder_name="${app_name}-${version}-${app_name_ending}"
	download_link="${base_link}/${version}/${artifact_name}"

	if [ "$purge" != true ]; then

		echo $progress_string_1
		echo
		curl -s --output-dir $TEMPD $download_link -O -L
		echo $progress_string_2
		echo

		mkdir -p "${folder}"
		mkdir -p "${folder}/links"

		if [ "$onefile" != true ]; then

			unzip -qq $TEMPD/$artifact_name -d $TEMPD
			chmod -R u+rw $TEMPD/dist/onedir/$folder_name
			mv -n $TEMPD/dist/onedir/$folder_name "${folder}"

		elif [ "$onefile" == true ]; then

			chmod u+rwx $TEMPD/$artifact_name
			mv -n $TEMPD/$artifact_name "${folder}"

		else

			echo "Unexpected error."
			exit 1

		fi

		# Create symlinks and clear up older versions
		if [[ "$prerelease" != true ]] && [[ "$versionspec" != true ]]; then

			# Default - pre-release or specific version not specified
			#
			# Create generic app_name sym link to latest release along with specific version numbered link

			if [ "$onefile" != true ]; then

				ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${folder_name}"

				echo "-not -name ${folder_name}" >>"${folder}"/stable_versions.txt

				# Record sym link names to inform user
				symstring="${folder_name}"

				if [ "$univlink" == true ]; then

					ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${app_name}"
					symstring="${app_name} or ${folder_name}"

				fi

			elif [ "$onefile" == true ]; then

				ln -sf "${folder}/${artifact_name}" "${folder}/links/${app_name}"
				ln -sf "${folder}/${artifact_name}" "${folder}/links/${artifact_name_name}"

				echo "-not -name ${folder_name}" >>"${folder}"/stable_versions.txt

				# Record sym link names to inform user
				symstring="${app_name} or ${folder_name}"

			else

				echo "Unexpected error."
				exit 1

			fi

			tail -n3 "${folder}"/stable_versions.txt >>"${folder}"/to_keep.txt
			mv "${folder}"/to_keep.txt "${folder}"/stable_versions.txt

			# Delete symlinks and folders not stored in stable_versions.txt and user_versions.txt
			find "${folder}"/links/"${app_name}"-v* $(cat "${folder}"/stable_versions.txt 2>/dev/null) $(cat "${folder}"/user_versions.txt 2>/dev/null) -delete
			find "${folder}"/"${app_name}"-v* $(cat "${folder}"/stable_versions.txt 2>/dev/null) $(cat "${folder}"/user_versions.txt 2>/dev/null) -delete

		else

			if [ "$onefile" != true ]; then
				ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${folder_name}"

				echo "-not -name ${folder_name}" >>"${folder}"/user_versions.txt

				# Record sym link names to inform user

				symstring=${folder_name}
			elif [ "$onefile" == true ]; then
				ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${folder_name}"

				echo "-not -name ${folder_name}" >>"${folder}"/user_versions.txt

				# Record sym link names to inform user

				symstring=${folder_name}
			else
				echo "Unexpected error."
				exit 1
			fi

		fi

		if [ "$path" = true ]; then

			# Check which files exist
			if [ $(test -f ~/.zshrc) ] && [[ "$onpath" = false ]]; then
				echo "Updating ~/.zshrc..."
				echo "export PATH=\"\$PATH:"${folder}"/links\"" >>~/.zshrc
			fi

			if [ $(test -f ~/.bashrc) ] && [[ "$onpath" = false ]]; then
				echo "Updating ~/.bashrc..."
				echo "export PATH=\"\$PATH:"${folder}"/links\"" >>~/.bashhrc
			fi
		fi

		echo $completion_string_1
		sleep 0.2
		if [ "$path" != true ] && [ "$onpath" != true ]; then
			echo
			echo
			echo "Add "${app_name}" to path by adding the following line to ~/.bashrc or ~/.zshrc:"
			echo "export PATH=\"\$PATH:"${folder}"/links\""
		fi
		echo
		echo
		echo "Re-open terminal and then type ${symstring} to get started."

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
	trap "exit 1" HUP INT PIPE QUIT TERM
	trap 'rm -rf $TEMPD' EXIT

}

set_variables() {

	app_name="hpcflow"
	base_link="https://github.com/hpcflow/hpcflow-new/releases/download"

	linux_ending_folder="linux-dir"
	macOS_ending_folder="macOS-dir"
	linux_ending_file="linux"
	macOS_ending_file="macOS"

	linux_install_dir=~/.local/share/hpcflow
	macOS_install_dir=~/Library/Application\ Support/hpcflow

	#latest_stable_releases="https://raw.githubusercontent.com/hpcflow/hpcflow-new/main/docs/source/released_binaries.yml"
	latest_stable_releases="https://raw.githubusercontent.com/hpcflow/hpcflow-new/dummy-stable/docs/source/released_binaries.yml"
	latest_prerelease_releases="https://raw.githubusercontent.com/hpcflow/hpcflow-new/develop/docs/source/released_binaries.yml"

	progress_string_1="Step 1 of 2: Downloading ${app_name} ..."
	progress_string_2="Step 2 of 2: Installing ${app_name} ..."
	completion_string_1="Installation of ${app_name} complete."

}

set_flags () {

	# Flag variables false by default
	purge=false
	path=false
	prerelease=false

	# Flag to note if user specified version
	versionspec=false
	# Flag recording if hpcflow symlink folder is on path
	onpath=false

}

make_tempdir () {

	# Make temp diretory and store path in a variable
	TEMPD=$(mktemp -d)

	# Exit if temp directory wasn't created successfully
	if [ ! -r "$TEMPD" ]; then
		echo >&2 "Failed to create temp directory for download"
		exit 1
	fi

}

parse_params () {

	# Assign command line variables and flags
	while [ $# -gt 0 ]; do

		if [[ $1 == *"--"* ]]; then

			param="${1/--/}"

			case $param in

				prerelease)
					prerelease=true
					;;
				purge)
					purge=true
					;;
				path)
					path=true
					;;
				onefile)
					onefile=true
					;;
				univlink)
					univlink=true
					;;
				version)
					version=$2
					versionspec=true
					;;
				folder)
					folder=$2
					;;
				*)
					echo "Unknown option ${param}"
					echo "Exiting..."
					exit 1

			esac

			# echo $1 $2 // Optional to see the parameter:value result

		fi

		shift

	done

}

set_OS_specific_variables () {

	# Set OS specific variables
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then

		folder=${folder:-${linux_install_dir}}

		if [[ "$onefile" = true ]]; then
			app_name_ending=$linux_ending_file
			file_name_ending=$linux_ending_file
		else
			app_name_ending=$linux_ending_folder
			file_name_ending="${linux_ending_folder}.zip"
		fi

	elif [[ "$OSTYPE" == "darwin"* ]]; then

		folder=${folder:-${macOS_install_dir}}

		if [[ "$onefile" = true ]]; then
			app_name_ending=$macOS_ending_file
			file_name_ending=$macOS_ending_file
		else
			app_name_ending=$macOS_ending_folder
			file_name_ending="${macOS_ending_folder}.zip"
		fi

	else
		echo "Operating system ${OSTYPE} not supported."
		exit 1
	fi

}

get_artifact_names () {

	# If prelease flag is set, default is latest prerelease, otherwise latest stable
	# Both overridden if version specified by user
	if [ "$prerelease" = true ]; then

		echo "Installing latest prerelease version."
		sleep 0.2

		artifact_name=$(curl -s $latest_prerelease_releases | grep "${file_name_ending}:" | cut -d ":" -f 1)
		version=$(echo $artifact_name | cut -d '-' -f 2)

	elif [ "$versionspec" = true ]; then

		echo "Installing ${app_name} version ${version}."
		sleep 0.2
		version=${version}
		artifact_name="${app_name}-${version}-${file_name_ending}"

	else

		echo "Installing latest stable version"
		sleep 0.2

		artifact_name=$(curl -s $latest_stable_releases | grep "${file_name_ending}:" | cut -d ":" -f 1)
		version=$(echo $artifact_name | cut -d '-' -f 2)

	fi

}

dummy_func () {
	prerelease=true
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	run_main "$@"
fi
