#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

teardown() {

}

@test "Install script runs" {
	run install-hpcflow-flags.sh
}

@test "Installs to correct location" {

	run install-hpcflow-flags.sh

	if [ "$OSTYPE" == "linux-gnu"* ]; then

	fi

	if [ "$OSTYPE" == "darwin"* ]; then

	fi

}