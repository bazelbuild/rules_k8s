#!/bin/bash

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
set -euo pipefail

LANGUAGE="$1"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/../lib/e2e-test-helpers.sh"

function create() {
   bazel build examples/hellogrpc/${LANGUAGE}/server:staging.create
   bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.create
}

function edit() {
   ./examples/hellogrpc/${LANGUAGE}/server/edit.sh "$1"
}

function update() {
   bazel build examples/hellogrpc/${LANGUAGE}/server:staging.apply
   bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.apply
}

function delete() {
   bazel build examples/hellogrpc/${LANGUAGE}/server:staging-deployment.describe
   bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging-deployment.describe
   bazel build examples/hellogrpc/${LANGUAGE}/server:staging.delete
   bazel-bin/examples/hellogrpc/${LANGUAGE}/server/staging.delete
   edit ''
}

bazel build "examples/hellogrpc/${LANGUAGE}/client"
CHECK_CLIENT="./bazel-bin/examples/hellogrpc/${LANGUAGE}/client/client"

create
trap "delete" EXIT
sleep 30
check_msg "$CHECK_CLIENT" "%s" hello-grpc-staging ''

for i in $RANDOM $RANDOM; do
  edit "$i"
  update
  sleep 15
  check_msg "$CHECK_CLIENT" "%s" hello-grpc-staging "$i"
done

# Replace the trap with a success message.
trap "delete; echo PASS" EXIT
