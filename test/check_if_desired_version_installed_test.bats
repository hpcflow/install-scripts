#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

@test "Continue if version not found" {

    folder=$BATS_TEST_TMPDIR

	touch "${folder}"/user_versions.txt
	touch "${folder}"/stable_versions.txt
    
    run bash -c '
		source src/install-hpcflow-flags.sh;
        version=v0.0.1
        app_name=:"test_app"
        check_if_desired_version_installed
        '

        assert_success 

}

@test "Exit if version found in user_versions.txt" {

    folder=$BATS_TEST_TMPDIR

	touch "${folder}"/user_versions.txt
	touch "${folder}"/stable_versions.txt

    echo "not -name hpcflow-v0.0.1-macOS-dir" >> "${folder}"/user_versions.txt
    
    run bash -c '
		source src/install-hpcflow-flags.sh;
        folder=$BATS_TEST_TMPDIR
	    touch "${folder}"/user_versions.txt
	    touch "${folder}"/stable_versions.txt
        echo "not -name hpcflow-v0.0.1-macOS-dir" >> "${folder}"/user_versions.txt
        version=v0.0.1
        app_name=:"hpcflow"
        app_name_ending=macOS-dir
        check_if_desired_version_installed
        '

        assert_output "test"

}