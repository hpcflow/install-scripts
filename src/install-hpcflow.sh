#!/bin/bash
run_main() {

	check_prerequisites

	get_rc_file

	set_variables

	set_flags

	make_tempdir

	parse_params "$@"

	set_OS_specific_variables

	make_main_folder

	get_artifact_names

	create_install_tracker_files

	check_if_desired_version_installed

	check_if_symlink_folder_on_path

	# Set variables for download and install
	folder_name="${app_name}-${version}-${app_name_ending}"
	download_link="${base_link}/${version}/${artifact_name}"

	if [ "$purge" != true ]; then

		download_artifact_to_temp

		make_destination_folders

		if [ "$onefile" != true ]; then

			unzip_and_move_one_folder_version

		elif [ "$onefile" == true ]; then

			unzip_and_move_onefile_version

		else

			echo "Unexpected error."
			exit 1

		fi

		create_versioned_symlink

		if [ "$univlink" == true ]; then

			create_universal_symlink

		fi

		clear_up_installed_versions

		if [ "$path" = true ]; then

			add_to_path

		fi

		print_post_install_info

	elif [ "$purge" = true ]; then

		purge_application

	fi

	# Make sure temp directory is deleted on exit
	trap "exit 1" HUP INT PIPE QUIT TERM
	trap 'rm -rf $TEMPD' EXIT

}

is_software_installed() {
	# Check that software is available on system
	# Exit if any software is missing
    software_missing=false
    for tool in $@
    do
        if ! command -v $tool &> /dev/null
        then
            echo "$tool could not be found"
            software_missing=true
        fi
    done

    if $software_missing
    then
        exit 1
    fi
}

check_prerequisites() {
	# Check whether prerequisite software is available
	is_software_installed mktemp curl grep unzip
}

set_variables() {

	app_name="hpcflow"
	base_link="https://github.com/hpcflow/${app_name}-new/releases/download"

	linux_ending_folder="linux-dir"
	macOS_ending_folder="macOS-dir"
	linux_ending_file="linux"
	macOS_ending_file="macOS"

	linux_install_dir=~/.local/share/$app_name
	macOS_install_dir=~/Library/Application\ Support/$app_name

	latest_stable_releases="https://raw.githubusercontent.com/hpcflow/${app_name}-new/dummy-stable/docs/source/released_binaries.yml"
	latest_prerelease_releases="https://raw.githubusercontent.com/hpcflow/${app_name}-new/develop/docs/source/released_binaries.yml"

	progress_string_1="Step 1 of 2: Downloading ${app_name} ..."
	progress_string_2="Step 2 of 2: Installing ${app_name} ..."
	completion_string_1="Installation of ${app_name} complete."

}

set_flags() {

	# Flag variables false by default
	purge=false
	path=false
	prerelease=false

	# Flag to note if user specified version
	versionspec=false
	# Flag recording if symlink folder is on path
	onpath=false

}

make_tempdir() {

	# Make temp diretory and store path in a variable
	TEMPD=$(mktemp -d)

	# Exit if temp directory wasn't created successfully
	if [ ! -r "$TEMPD" ]; then
		echo >&2 "Failed to create temp directory for download"
		exit 1
	fi

}

parse_params() {

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
				;;

			esac

			# echo $1 $2 // Optional to see the parameter:value result

		fi

		shift

	done

}

set_OS_specific_variables() {

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

get_artifact_names() {

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

make_main_folder() {
	mkdir -p "${folder}"
}

create_install_tracker_files() {
	touch "${folder}"/user_versions.txt
	touch "${folder}"/prerelease_versions.txt
	touch "${folder}"/stable_versions.txt
}

check_if_desired_version_installed() {

	if [ $(grep -c "${version}-${app_name_ending}" "${folder}"/user_versions.txt) -ge 1 ] || [ $(grep -c "${version}-${app_name_ending}" "${folder}"/stable_versions.txt) -ge 1 ]; then

		echo "${app_name} ${version} already installed on this system... "
		sleep 0.2
		echo "Exiting..."
		exit 1

	fi

}

check_if_symlink_folder_on_path() {

	# Check if folders on path already
	case :$PATH: in
	*:"${folder}"/links:) onpath=true ;;
	*) ;;
	esac

}

download_artifact_to_temp() {

	echo $progress_string_1
	echo
	curl -s --output "${TEMPD}/${artifact_name}" $download_link -O -L
	echo $progress_string_2
	echo

}

make_destination_folders() {

	mkdir -p "${folder}"
	mkdir -p "${folder}/links"

}

unzip_and_move_one_folder_version() {

	unzip -qq $TEMPD/$artifact_name -d $TEMPD
	chmod -R u+rw $TEMPD/dist/onedir/$folder_name
	mv -n $TEMPD/dist/onedir/$folder_name "${folder}"

}

unzip_and_move_onefile_version() {

	chmod u+rwx $TEMPD/$artifact_name
	mv -n $TEMPD/$artifact_name "${folder}"

}

create_versioned_symlink() {

	if [ "$onefile" == true ]; then

		ln -sf "${folder}/${artifact_name}" "${folder}/links/${artifact_name}"
		install_name=${artifact_name}
		versioned_symstring="${artifact_name}"

	else

		ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${folder_name}"
		install_name=${folder_name}
		versioned_symstring="${folder_name}"

	fi

	if [ "$versionspec" == true ]; then
		echo "-not -name ${install_name}" >>"${folder}"/user_versions.txt
	elif [ "$prerelease" == true ]; then
		echo "-not -name ${install_name}" >>"${folder}"/prerelease_versions.txt
	else
		echo "-not -name ${install_name}" >>"${folder}"/stable_versions.txt
	fi

}

create_universal_symlink() {

		if [ "$onefile" == true ]; then

			if [ "$prerelease" == true ]; then
				ln -sf "${folder}/${artifact_name}" "${folder}/links/${app_name}-dev"
				univ_symstring="${app_name}-dev"
			else
				ln -sf "${folder}/${artifact_name}" "${folder}/links/${app_name}}"
				univ_symstring="${app_name}"
			fi

		else

			if [ "$prerelease" == true ]; then
				ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${app_name}-dev"
				univ_symstring="${app_name}-dev"
			else
				ln -sf "${folder}/${folder_name}/${folder_name}" "${folder}/links/${app_name}"
				univ_symstring="${app_name}"
			fi

		fi

}

clear_up_installed_versions () {

	# Keep most recent 3 latest stable versions
	tail -n3 "${folder}/stable_versions.txt" > "${folder}/stable_versions_to_keep.txt"
	mv "${folder}/stable_versions_to_keep.txt" "${folder}/stable_versions.txt"

	# Keep most recent 3 latest prerelease versions
	tail -n3 "${folder}/prerelease_versions.txt" > "${folder}/prerelease_versions_to_keep.txt"
	mv "${folder}/prerelease_versions_to_keep.txt" "${folder}/prerelease_versions.txt"

	# Remove versioned symlinks
	find "${folder}"/links/"${app_name}"-v* $(cat "${folder}"/stable_versions.txt 2>/dev/null) $(cat "${folder}"/user_versions.txt 2>/dev/null) $(cat "${folder}"/prerelease_versions.txt 2>/dev/null) -delete

	# Remove installed apps
	find "${folder}"/"${app_name}"-v* -maxdepth 0 $(cat "${folder}"/stable_versions.txt 2>/dev/null) $(cat "${folder}"/user_versions.txt 2>/dev/null) $(cat "${folder}"/prerelease_versions.txt 2>/dev/null) -delete

}

keep_most_recent_stable () {

	tail -n3 "${folder}"/stable_versions.txt >>"${folder}"/to_keep.txt

	# Delete symlinks and folders not stored in stable_versions.txt and user_versions.txt
	find "${folder}"/links/"${app_name}"-v* $(cat "${folder}"/stable_versions.txt 2>/dev/null) $(cat "${folder}"/user_versions.txt 2>/dev/null) -delete
	find "${folder}"/"${app_name}"-v* $(cat "${folder}"/stable_versions.txt 2>/dev/null) $(cat "${folder}"/user_versions.txt 2>/dev/null) -delete

}

get_rc_file () {
	# Store .bashrc or .zshrc in a variable
	if [ -f ~/.zshrc ]; then
		rc_file="~/.zshrc"
	elif [ -f ~/.bashrc ]; then
		rc_file="~/.bashrc"
	fi
}

add_to_path () {

	# Update the (bash/zsh)rc file
	if [ -f $rc_file ] && [[ "$onpath" = false ]]; then
		echo "Updating $rc_file..."
		echo "export PATH=\"\$PATH:"${folder}"/links\"" >> $rc_file
	fi
}

print_post_install_info () {


	echo $completion_string_1
	sleep 0.2
	if [ "$path" != true ] && [ "$onpath" != true ]; then
		echo
		echo
		echo "Add "${app_name}" to path by adding the following line to ${rc_file}:"
		echo "export PATH=\"\$PATH:"${folder}"/links\""
	fi
	echo
	echo
	if [ "$univlink" == true ]; then
		echo "Re-open terminal and type \"${univ_symstring}\" to get started, or type \"source ${rc_file}\" followed by \"${univ_symstring}\" to start immediately."
	else
		echo "Re-open terminal and type \"${versioned_symstring}\" to get started, or type \"source ${rc_file}\" followed by \"${versioned_symstring}\" to start immediately."
	fi

}

purge_application (){

	echo "Purging local install of "${app_name}"..."
	sleep 0.2
	echo "I say we take off and nuke the entire site from orbit. It's the only way to be sure."
	# echo "Deleting "${app_name}" folder "${folder}"..."
	# sleep 0.2
	#rm -r  "${folder}"
	# echo "Removing "${app_name}" folder "$folder}" from path..."
	# sleep 0.2
	# COMMAND GOES HERE

}

dummy_func() {
	prerelease=true
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	run_main "$@"
fi
