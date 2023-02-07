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