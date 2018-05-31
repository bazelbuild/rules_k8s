#!/bin/bash
set -e

# The schema directory has to have the structure 'kubernetes-json-schema/master', so do that in a tmpdir
tmp_dir=$(mktemp -d)

function cleanup() {
    rm -rf $tmp_dir
}

trap "cleanup" EXIT

schema_dir=$tmp_dir/kubernetes-json-schema/master/
mkdir -p $schema_dir
ln -s $(pwd)/external/kubeval_schemas/* $schema_dir

cat %{config} | %{kubeval} file://$tmp_dir
