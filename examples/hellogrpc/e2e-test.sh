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

source ./examples/util.sh

# copt flag is needed to compila a gRPC dependency (@udp)
# verbose_failures is added for better error debugging
BAZEL_FLAGS="--copt=-Wno-c99-extensions --verbose_failures"

validate_args $@
shift 2

function fail() {
  echo "FAILURE: $1"
  exit 1
}

function CONTAINS() {
  local complete="${1}"
  local substring="${2}"

  echo "${complete}" | grep -Fsq -- "${substring}"
}

function EXPECT_CONTAINS() {
  local complete="${1}"
  local substring="${2}"
  local message="${3:-Expected '${substring}' not found in '${complete}'}"

  echo Checking "$1" contains "$2"
  CONTAINS "${complete}" "${substring}" || fail "$message"
}

function CONTAINS_PATTERN() {
  local complete="${1}"
  local substring="${2}"

  echo "${complete}" | grep -Esq -- "${substring}"
}

function EXPECT_CONTAINS_PATTERN() {
  local complete="${1}"
  local substring="${2}"
  local message="${3:-Expected '${substring}' not found in '${complete}'}"

  echo Checking "$1" contains pattern "$2"
  CONTAINS_PATTERN "${complete}" "${substring}" || fail "$message"
}

# Ensure there is an ip address for hell-grpc-staging:50051
apply-lb() {
  echo Applying service...
  bazel build $BAZEL_FLAGS examples/hellogrpc:staging-service.apply
  bazel-bin/examples/hellogrpc/staging-service.apply
}

create() {
  echo Creating $LANGUAGE...
  bazel build $BAZEL_FLAGS examples/hellogrpc/${LANGUAGE}/server:staging.create
  bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.create
}

check_msg() {
  bazel build $BAZEL_FLAGS examples/hellogrpc/${LANGUAGE}/client

  while [[ -z $(get_lb_ip $local hello-grpc-staging) ]]; do
    echo "service has not yet received an IP address, sleeping for 5s..."
    sleep 10
  done

  # Wait some more for after IP address allocation for the service to come
  # alive
  echo "Got IP Adress! Sleeping 30s more for service to come alive..."
  sleep 30

  # Make Bazel generate a temporary script that runs the client executable.
  tmp_exec=hellogrpc_${LANGUAGE}_client
  # This will only generate the temp executable. It won't actually run it.
  bazel run $BAZEL_FLAGS //examples/hellogrpc/${LANGUAGE}/client --script_path=${tmp_exec}
  OUTPUT=$(./${tmp_exec} $(get_lb_ip $local hello-grpc-staging))
  rm ${tmp_exec}
  echo Checking response from service: "${OUTPUT}" matches: "DEMO$1<space>"
  echo "${OUTPUT}" | grep "DEMO$1[ ]"
}

edit() {
  echo Setting $LANGUAGE to "$1"
  ./examples/hellogrpc/${LANGUAGE}/server/edit.sh "$1"
}

update() {
  echo Updating $LANGUAGE...
  bazel build $BAZEL_FLAGS examples/hellogrpc/${LANGUAGE}/server:staging.replace
  bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.replace
}

delete() {
  echo Deleting $LANGUAGE...
  kubectl get all --namespace="${namespace}" --selector=app=hello-grpc-staging
  bazel build $BAZEL_FLAGS examples/hellogrpc/${LANGUAGE}/server:staging.describe
  bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.describe || echo "Resource didn't exist!"
  bazel build $BAZEL_FLAGS examples/hellogrpc/${LANGUAGE}/server:staging.delete
  bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.delete
}

check_kubeconfig_args() {
  for cmd in apply delete; do
    bazel build $BAZEL_FLAGS examples/hellogrpc:staging-deployment-with-kubeconfig.${cmd}
    OUTPUT="$(cat ./bazel-bin/examples/hellogrpc/staging-deployment-with-kubeconfig.${cmd})"
    EXPECT_CONTAINS_PATTERN "${OUTPUT}" "--kubeconfig=\S*/examples/hellogrpc/kubeconfig.out"
  done
}

# e2e test that checks that args are added to the kubectl apply command
check_kubectl_args() {
    # Checks that bazel run <some target> does pick up the args attr and
    # passes it to the execution of the template
    EXPECT_CONTAINS "$(bazel run $BAZEL_FLAGS examples/hellogrpc:staging.apply)" "apply --v=2"
    # Checks that bazel run <some target> -- <some extra arg> does pass both the
    # args in the attr as well as the <some extra arg> to the execution of the
    # template
    EXPECT_CONTAINS "$(bazel run $BAZEL_FLAGS examples/hellogrpc:staging.apply -- --v=1)" "apply --v=2 --v=1"
}

check_kubeconfig_args

check_kubectl_args

apply-lb

while [[ -n "${1:-}" ]]; do
  LANGUAGE="$1"
  shift

  delete &> /dev/null || true
  create
  set +o xtrace
  trap "echo FAILED, cleaning up...; delete" EXIT
  set -o xtrace
  sleep 25
  check_msg ""

  for i in $RANDOM $RANDOM; do
    edit "$i"
    update
    # Don't let K8s slowness cause flakes.
    sleep 25
    check_msg "$i"
  done
  delete
done

# Replace the trap with a success message.
trap "echo PASS" EXIT
