#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

@test "Test user version tracker file created" {

    run bash -c '
		source src/install-hpcflow-flags.sh;
        folder=${BATS_TEST_TMPDIR}
        create_install_tracker_files
        '

        assert [ -e "${BATS_TEST_TMPDIR}/user_versions.txt" ]

}

@test "Test stable version tracker file created" {

    run bash -c '
		source src/install-hpcflow-flags.sh;
        folder=${BATS_TEST_TMPDIR}
        create_install_tracker_files
        '

        assert [ -e "${BATS_TEST_TMPDIR}/stable_versions.txt" ]

}