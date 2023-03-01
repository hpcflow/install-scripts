#!/usr/bin/env bash

setup() {
	load 'test_helper/common-setup'
	_common_setup
}

@test "Keep three versions in stable_versions.txt" {

    folder=$BATS_TEST_TMPDIR;

    run bash -c '
		source src/install-hpcflow-flags.sh;
        folder=$BATS_TEST_TMPDIR;
        app_name="hpcflow"
        mkdir $folder/links/
	    touch $folder/user_versions.txt;
	    touch $folder/stable_versions.txt;
        touch $folder/links/hpcflow-v0.0.1-macOS-dir
        touch $folder/links/hpcflow-v0.0.2-macOS-dir
        touch $folder/links/hpcflow-v0.0.3-macOS-dir
        touch $folder/links/hpcflow-v0.0.4-macOS-dir
        touch $folder/hpcflow-v0.0.1-macOS-dir
        touch $folder/hpcflow-v0.0.2-macOS-dir
        touch $folder/hpcflow-v0.0.3-macOS-dir
        touch $folder/hpcflow-v0.0.4-macOS-dir
        echo "-not -name hpcflow-v0.0.1-macOS-dir" >> $folder/stable_versions.txt;
        echo "-not -name hpcflow-v0.0.2-macOS-dir" >> $folder/stable_versions.txt;
        echo "-not -name hpcflow-v0.0.3-macOS-dir" >> $folder/stable_versions.txt;
        echo "-not -name hpcflow-v0.0.4-macOS-dir" >> $folder/stable_versions.txt;
        keep_most_recent_stable
        wc -l $folder/stable_versions.txt
        '
        # What is going on here with the spaces??
        assert_output "       3 $folder/stable_versions.txt"
    

}

@test "Delete versions not in stable_versions.txt" {

    folder=$BATS_TEST_TMPDIR;

    run bash -c '
		source src/install-hpcflow-flags.sh;
        folder=$BATS_TEST_TMPDIR;
        app_name="hpcflow"
        mkdir $folder/links/
	    touch $folder/user_versions.txt;
	    touch $folder/stable_versions.txt;
        touch $folder/links/hpcflow-v0.0.1-macOS-dir
        touch $folder/links/hpcflow-v0.0.2-macOS-dir
        touch $folder/links/hpcflow-v0.0.3-macOS-dir
        touch $folder/links/hpcflow-v0.0.4-macOS-dir
        touch $folder/hpcflow-v0.0.1-macOS-dir
        touch $folder/hpcflow-v0.0.2-macOS-dir
        touch $folder/hpcflow-v0.0.3-macOS-dir
        touch $folder/hpcflow-v0.0.4-macOS-dir
        echo "-not -name hpcflow-v0.0.2-macOS-dir" >> $folder/stable_versions.txt;
        echo "-not -name hpcflow-v0.0.3-macOS-dir" >> $folder/stable_versions.txt;
        echo "-not -name hpcflow-v0.0.4-macOS-dir" >> $folder/stable_versions.txt;
        keep_most_recent_stable
        wc -l $folder/stable_versions.txt
        '

        assert [ ! -e "$folder/links/hpcflow-v0.0.1-macOS-dir" ]

}

@test "Delete versions not in user_versions.txt" {

}