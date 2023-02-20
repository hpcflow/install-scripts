#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

# bats test_tags=tag:set_OS_specific_variables
@test "set_OS_specific_variables: Keeps user specified folder" {
	run bash -c '
		source src/install-hpcflow-flags.sh;
		folder=user_spec;
		set_OS_specific_variables; 
		echo $folder
		'
	assert_output user_spec
}

# bats test_tags=tag:set_OS_specific_variables
@test "set_OS_specific_variables: Fails if OSTYPE unknown" {
	run bash -c '
		source src/install-hpcflow-flags.sh;
		OSTYPE=unknown;
		set_OS_specific_variables
		'
	assert_failure
}

# bats test_tags=tag:set_OS_specific_variables
@test "set_OS_specific_variables: OSTYPE darwin generates correct output, onefile" {
	run bash -c '
		source src/install-hpcflow-flags.sh;
		OSTYPE=darwin;
		onefile=true;
		macOS_ending_file=macOS
		set_OS_specific_variables
		echo $app_name_ending, $file_name_ending
		'
	assert_output "macOS, macOS"
}

# bats test_tags=tag:set_OS_specific_variables
@test "set_OS_specific_variables: OSTYPE darwin generates correct output" {
	run bash -c '
		source src/install-hpcflow-flags.sh;
		OSTYPE=darwin;
		macOS_ending_folder=macOS-dir
		set_OS_specific_variables
		echo $app_name_ending, $file_name_ending
		'
	assert_output "macOS-dir, macOS-dir.zip"
}

# bats test_tags=tag:set_OS_specific_variables
@test "set_OS_specific_variables: OSTYPE linux-gnu generates correct output, onefile" {
	run bash -c '
		source src/install-hpcflow-flags.sh;
		OSTYPE=linux-gnu;
		onefile=true;
		linux_ending_file=linux
		set_OS_specific_variables
		echo $app_name_ending, $file_name_ending
		'
	assert_output "linux, linux"
}

# bats test_tags=tag:set_OS_specific_variables
@test "set_OS_specific_variables: OSTYPE linux-gnu generates correct output" {
	run bash -c '
		source src/install-hpcflow-flags.sh;
		OSTYPE=linux-gnu;
		linux_ending_folder=linux-dir
		set_OS_specific_variables
		echo $app_name_ending, $file_name_ending
		'
	assert_output "linux-dir, linux-dir.zip"
}