#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

# bats test_tags=tag:make_tempdir
@test "make_tempdir: Temp folder creation" {
	skip
	run bash -c '
		source src/install-hpcflow-flags.sh;
		make_tempdir;
		echo $TEMPD
		'
	assert [ -e $TEMPD ]
}