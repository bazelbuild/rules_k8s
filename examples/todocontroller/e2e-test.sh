#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

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
LANGUAGE="$1"

function get_lb_ip() {
  kubectl --namespace="${namespace}" get service hello-grpc-staging \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

function create() {
  echo Creating $LANGUAGE...
  bazel build examples/todocontroller/${LANGUAGE}:staging.create
  bazel-bin/examples/todocontroller/${LANGUAGE}/staging.create
  bazel build examples/todocontroller:example-todo.create
  bazel-bin/examples/todocontroller/example-todo.create
}

function check_msg() {
  bazel build examples/todocontroller:example-todo.describe

  NUM_ATTEMPTS=10
  OUTPUT=""
  for iattempt in $(seq 1 $NUM_ATTEMPTS); do
    OUTPUT=$(./bazel-bin/examples/todocontroller/example-todo.describe)
    echo "Attempt ${iattempt}/${NUM_ATTEMPTS}: Checking whether server is done with update"
    echo "${OUTPUT}" | grep "Done:[ ]*true"
    retval=$?
    if [ $retval -ne 0 ]; then
      echo "Controller update isn't done yet. Sleeping 40s..."
      sleep 40
    else
      break
    fi
  done;
  echo Checking response from service: "${OUTPUT}" matches: "DEMO$1<space>"
  echo "${OUTPUT}" | grep "DEMO$1[ ]"
}

function edit() {
  echo Editing $LANGUAGE to $1...
  ./examples/todocontroller/${LANGUAGE}/edit.sh "$1"
}

function update_controller() {
  echo Replacing $LANGUAGE controller...
  bazel build examples/todocontroller/${LANGUAGE}:controller-deployment.replace
  bazel-bin/examples/todocontroller/${LANGUAGE}/controller-deployment.replace
}

function update_todo() {
  echo Replacing example-todo...
  bazel build examples/todocontroller:example-todo.replace
  bazel-bin/examples/todocontroller/example-todo.replace
}

function delete() {
  echo Deleting $LANGUAGE...
  bazel run examples/todocontroller/example-todo.describe
  bazel run examples/todocontroller/${LANGUAGE}:controller-deployment.describe

  bazel build examples/todocontroller/example-todo.delete
  bazel-bin/examples/todocontroller/example-todo.delete
  bazel build examples/todocontroller/${LANGUAGE}:staging.delete
  bazel-bin/examples/todocontroller/${LANGUAGE}/staging.delete
}

function check_reverse_delete_k8s_object() {
  echo Checking deletion in reverse order via k8s_object...
  bazel run examples/todocontroller:joined.apply
  gcloud compute project-info describe | grep -B 1 -A 1 ADDRESSES
  echo "Done with apply. Wait 5s before triggering delete"
  sleep 5
  gcloud compute project-info describe | grep -B 1 -A 1 ADDRESSES
  bazel run examples/todocontroller:joined.delete || echo "ERROR: joined.delete failed but ignoring flakiness!"
}

function check_reverse_delete_k8s_objects() {
  echo Checking deletion in reverse order via k8s_objects...
  bazel run examples/todocontroller:everything.apply
  gcloud compute project-info describe | grep -B 1 -A 1 ADDRESSES
  echo "Done with apply. Wait 5s before triggering delete"
  sleep 5
  gcloud compute project-info describe | grep -B 1 -A 1 ADDRESSES
  bazel run examples/todocontroller:everything.delete || echo "ERROR: everything.delete failed but ignoring flakiness!"
}

check_reverse_delete_k8s_object
check_reverse_delete_k8s_objects

delete &> /dev/null || true
create
set +o xtrace
trap "echo FAILED, cleaning up...; delete" EXIT
set -o xtrace
sleep 25
check_msg ""

for i in $RANDOM $RANDOM; do
  edit "$i"
  update_controller
  # Don't let K8s slowness cause flakes.
  sleep 40
  update_todo
  check_msg "$i"
done

# Replace the trap with a success message.
trap "echo PASS" EXIT
