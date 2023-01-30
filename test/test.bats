#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

@test "Install script runs" {
	run install-hpcflow-flags.sh
}
