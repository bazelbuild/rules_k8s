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
  echo "Usage: $(basename $0) <language ...>"
fi

get_lb_ip() {
  kubectl --namespace="${E2E_NAMESPACE}" get service hello-grpc-staging \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

# Ensure there is an ip address for hell-grpc-staging:50051
apply-lb() {
  echo Applying service...
  bazel run examples/hellogrpc/staging-service.apply
}

create() {
  echo Creating $LANGUAGE...
  bazel run examples/hellogrpc/${LANGUAGE}/server:staging.create
}

check_msg() {
  bazel build examples/hellogrpc/${LANGUAGE}/client

  while [[ -z $(get_lb_ip) ]]; do
    echo "service has not yet received an IP address, sleeping for 5s..."
    sleep 5
  done

  OUTPUT=$(./bazel-bin/examples/hellogrpc/${LANGUAGE}/client/client $(get_lb_ip))
  echo Checking response from service: "${OUTPUT}" matches: "DEMO$1<space>"
  echo "${OUTPUT}" | grep "DEMO$1[ ]"
}

edit() {
  echo Setting $LANGUAGE to "$1"
  ./examples/hellogrpc/${LANGUAGE}/server/edit.sh "$1"
}

update() {
  echo Updating $LANGUAGE...
  bazel run examples/hellogrpc/${LANGUAGE}/server:staging.replace
}

delete() {
  echo Deleting $LANGUAGE...
  kubectl get all --namespace="${E2E_NAMESPACE}" --selector=app=hello-grpc-staging
  bazel run examples/hellogrpc/${LANGUAGE}/server:staging.describe || echo "Resource didn't exist!"
  bazel run examples/hellogrpc/${LANGUAGE}/server:staging.delete
}


apply-lb

while [[ -n "${1:-}" ]]; do
  LANGUAGE="$1"
  shift

  delete || true
  create
  trap "echo FAILED, cleaning up...; delete" EXIT
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
