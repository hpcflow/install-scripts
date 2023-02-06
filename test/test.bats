#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

@test "make_tempdir: Temp folder creation" {
	skip 'Ignore until I work out how to remove folder.'
	run bash -c 'source src/install-hpcflow-flags.sh; make_tempdir; echo $TEMPD'
	assert [ -e $TEMPD ]
}

@test "parse_params: Reads --prerelease flag" {
	run bash -c 'source src/install-hpcflow-flags.sh; prerelease=false; parse_params --prerelease; echo $prerelease'
	assert_output true
}

@test "parse_params: Reads --purge flag" {
	run bash -c 'source src/install-hpcflow-flags.sh; purge=false; parse_params --purge; echo $purge'
	assert_output true
}

@test "parse_params: Reads --path flag" {
	run bash -c 'source src/install-hpcflow-flags.sh; path=false; parse_params --path; echo $path'
	assert_output true
}

@test "parse_params: Reads --onefile flag" {
	run bash -c 'source src/install-hpcflow-flags.sh; onefile=false; parse_params --onefile; echo $onefile'
	assert_output true
}

@test "parse_params: Reads --univlink flag" {
	run bash -c 'source src/install-hpcflow-flags.sh; univlink=false; parse_params --univlink; echo $univlink'
	assert_output true
}

@test "parse_params: Reads --version option" {
	run bash -c 'source src/install-hpcflow-flags.sh; version=default; parse_params --version v0.0.1; echo $version'
	assert_output "v0.0.1"
}

@test "parse_params: Sets versionspec flag if version specified" {
	run bash -c 'source src/install-hpcflow-flags.sh; version=default; versionspec=false; parse_params --version v0.0.1; echo $versionspec'
	assert_output true
}

@test "parse_params: Reads --folder option" {
	run bash -c 'source src/install-hpcflow-flags.sh; folder=default; parse_params --folder ~/custom/folder; echo $folder'
	assert_output ~/custom/folder
}

@test "parse_params: Fails with unknown flag" {
	run bash -c 'source src/install-hpcflow-flags.sh; parse_params --unknown_flag'
	assert_failure
}

@test "parse_params: Fails with unknown option" {
	run bash -c 'source src/install-hpcflow-flags.sh; parse_params --unknown_option foo'
	assert_failure
}

@test "set_OS_specific_variables: Keeps user specified folder" {
	run bash -c 'source src/install-hpcflow-flags.sh; folder=user_spec; set_OS_specific_variables; echo $folder'
	assert_output user_spec
}