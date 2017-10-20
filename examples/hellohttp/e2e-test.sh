#!/bin/bash -e

# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LANGUAGE="$1"

function get_lb_ip() {
    kubectl --namespace=${USER} get service hello-http-staging \
	-o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

function check_msg() {
   OUTPUT=$(curl http://$(get_lb_ip):8080)
   echo Checking response from service: "${OUTPUT}" matches: "DEMO$1<space>"
   echo "${OUTPUT}" | grep "DEMO$1[ ]"
}

function edit() {
   ./examples/hellohttp/${LANGUAGE}/edit.sh "$1"
}

function apply() {
   bazel run examples/hellohttp/${LANGUAGE}:staging.apply
}

function delete() {
   bazel run examples/hellohttp/${LANGUAGE}:staging.describe
   bazel run examples/hellohttp/${LANGUAGE}:staging.delete
}

function check_bad_substitution() {
    echo Checking a bad substitution
    if ! bazel run examples/hellohttp:error-on-run;
    then
	echo "Success, substitution failed."
	return
    else
	echo "Bad substitution should fail!"
	exit 1
    fi
}

function check_no_images_resolution() {
    echo Checking resolution with no images attribute.
    bazel build examples/hellohttp:resolve-external
    OUTPUT=$(bazel-bin/examples/hellohttp/resolve-external 2>&1)
    echo Checking output: "${OUTPUT}" matches: "/pause@"
    echo "${OUTPUT}" | grep "[/]pause[@]"
}

check_bad_substitution
check_no_images_resolution

apply
trap "delete" EXIT
sleep 25
check_msg

for i in $RANDOM $RANDOM; do
  edit "$i"
  apply
  # Don't let k8s slowness cause flakes.
  sleep 25
  check_msg "$i"
done

# Replace the trap with a success message.
trap "delete; echo PASS" EXIT
