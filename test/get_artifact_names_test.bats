#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

# bats test_tags=tag:get_artifact_names
@test "test get artifact name stable" {

    # NOTE: This relies on contents of release_binaries.yaml taking the form that the stubbed curl
    # function returns

    function curl() { echo "
        hpcflow-v0.0.1-win.exe: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-win.exe
        hpcflow-v0.0.1-macOS: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-macOS
        hpcflow-v0.0.1-linux: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-linux
        hpcflow-v0.0.1-win-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-win-dir.zip
        hpcflow-v0.0.1-macOS-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-macOS-dir.zip
        hpcflow-v0.0.1-linux-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-linux-dir.zip
        "
    }
    export -f curl

    source src/install-hpcflow-flags.sh

    run bash -c '
        source src/install-hpcflow-flags.sh
        file_name_ending=macOS-dir.zip
        get_artifact_names 1> /dev/null
        echo $version
        '
    assert_output "v0.0.1"

}

@test "test get artifact name prerelease" {

    # NOTE: This relies on contents of release_binaries.yaml taking the form that the stubbed curl
    # function returns

    function curl() { echo "
        hpcflow-v0.0.1-win.exe: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-win.exe
        hpcflow-v0.0.1-macOS: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-macOS
        hpcflow-v0.0.1-linux: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-linux
        hpcflow-v0.0.1-win-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-win-dir.zip
        hpcflow-v0.0.1-macOS-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-macOS-dir.zip
        hpcflow-v0.0.1-linux-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-linux-dir.zip
        "
    }
    export -f curl

    source src/install-hpcflow-flags.sh

    run bash -c '
        source src/install-hpcflow-flags.sh
        file_name_ending=macOS-dir.zip
        prerelease=true
        get_artifact_names 1> /dev/null
        echo $version
        '
    assert_output "v0.0.1"

}

@test "test get artifact name user specified version" {

    # NOTE: This relies on contents of release_binaries.yaml taking the form that the stubbed curl
    # function returns

    function curl() { echo "
        hpcflow-v0.0.1-win.exe: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-win.exe
        hpcflow-v0.0.1-macOS: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-macOS
        hpcflow-v0.0.1-linux: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-linux
        hpcflow-v0.0.1-win-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-win-dir.zip
        hpcflow-v0.0.1-macOS-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-macOS-dir.zip
        hpcflow-v0.0.1-linux-dir.zip: https://github.com/hpcflow/hpcflow-new/releases/download/v0.0.1/hpcflow-v0.0.1-linux-dir.zip
        "
    }
    export -f curl

    source src/install-hpcflow-flags.sh

    run bash -c '
        source src/install-hpcflow-flags.sh
        file_name_ending=macOS-dir.zip
        versionspec=true
        version=v0.0.1
        app_name=hpcflow
        get_artifact_names 1> /dev/null
        echo $artifact_name
        '
    assert_output "hpcflow-v0.0.1-macOS-dir.zip"

}