#!/usr/bin/env bash
set -e

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

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

if [[ -z "${1:-}" ]]; then
  echo "Usage: $(basename $0) <kubernetes namespace> <language ...>"
  exit 1
fi
namespace="$1"
shift
if [[ -z "${1:-}" ]]; then
  echo "ERROR: Languages not provided!"
  echo "Usage: $(basename $0) <kubernetes namespace> <language ...>"
  exit 1
fi

get_lb_ip() {
    kubectl --namespace="${namespace}" get service hello-http-staging \
      -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

# Ensure there is an ip address for hello-http-staging:8080
apply-lb() {
  echo Applying service...
  bazel run examples/hellohttp:staging-service.apply
}

check_msg() {
   while [[ -z $(get_lb_ip) ]]; do
     echo "service has not yet received an IP address, sleeping for 5s..."
     sleep 10
   done
   # Wait some more for after IP address allocation for the service to come
   # alive
   echo "Got IP Adress! Sleeping 30s more for service to come alive..."
   sleep 30
   OUTPUT=$(curl http://$(get_lb_ip):8080)
   echo Checking response from service: "${OUTPUT}" matches: "DEMO$1<space>"
   echo "${OUTPUT}" | grep "DEMO$1[ ]"
}

edit() {
  echo Setting $LANGUAGE to "$1"
  ./examples/hellohttp/${LANGUAGE}/edit.sh "$1"
}

apply() {
  echo Applying $LANGUAGE...
  bazel run examples/hellohttp/${LANGUAGE}:staging.apply
}

delete() {
  echo Deleting $LANGUAGE...
  kubectl get all --namespace="${namespace}" --selector=app=hello-http-staging
  bazel run examples/hellohttp/${LANGUAGE}:staging.describe
  bazel run examples/hellohttp/${LANGUAGE}:staging.delete
}

check_bad_substitution() {
  echo Checking a bad substitution...
  if ! bazel run examples/hellohttp:error-on-run; then
    echo "Success, substitution failed."
    return 0
  else
    echo "Bad substitution should fail!"
    exit 1
  fi
}

check_no_images_resolution() {
    echo Checking resolution with no images attribute...
    bazel build examples/hellohttp:resolve-external
    OUTPUT=$(bazel-bin/examples/hellohttp/resolve-external 2>&1)
    echo Checking output: "${OUTPUT}" matches: "/pause@"
    echo "${OUTPUT}" | grep "[/]pause[@]"
}

# e2e test that checks that --v=2 is added to the java kubectl apply command
# also tests that --help can be passed in as a cli argument
check_kubectl_args() {
     
    # checking that --v=2 is passed in via kubect_arguments in 
    # the java BUILD file
    FILE="./bazel-bin/examples/hellohttp/java/staging.apply"
    echo Checking kubectl args in file: "$FILE"
    bazel build examples/hellohttp/java:staging.apply
    if [ ! -f "$FILE" ]; then
        echo "FAIL: File '$FILE' not found!"
        exit 1
    fi
    if grep -q -- "--v=2" "$FILE"; then
      echo "PASS: Success, found argument."
    else
      echo "FAIL: Did not find --v=2 argument!"
      exit 1
    fi

    # passing in --help to kubectl
    OUTPUT=$(bazel run examples/hellohttp/go:staging.apply -- --help 2>&1)
    if echo "$OUTPUT" | grep -q Examples:; then
      echo "PASS: Success, found 'Examples:' argument was passed in"
      return 0
    else
      echo "FAIL: Did not find ouput word 'Examples:' --help was not passed to kubectl"
      exit 1
    fi
}

check_bad_substitution
check_no_images_resolution
check_kubectl_args

apply-lb

# Test each requested language
while [[ -n "${1:-}" ]]; do
  LANGUAGE="$1"
  shift

  apply # apply will handle already created
  set +o xtrace
  trap "echo FAILED, cleaning up...; delete" EXIT
  set -o xtrace
  sleep 25
  check_msg ""

  for i in $RANDOM $RANDOM; do
    edit "$i"
    apply
    # Don't let k8s slowness cause flakes.
    sleep 25
    check_msg "$i"
  done
done

# Replace the trap with a success message.
trap "echo PASS" EXIT
