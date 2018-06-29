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

set -o errexit
set -o nounset

check-plat() {
  local plat="$(uname -s)"
  if [[ $plat != Linux ]]; then
	  echo "System must be Linux, found: $plat"
	  return 1
  fi
}

check-plat

if [[ -n "${HELLO_WORLD:-}" ]]; then
  # Log into GCR
  docker login -u _json_key -p "${GOOGLE_JSON_KEY}" https://us.gcr.io
  # Log into gcloud
  echo -n "${GOOGLE_JSON_KEY}" > keyfile.json
  gcloud auth activate-service-account --key-file keyfile.json
  rm -f keyfile.json
  gcloud config set core/project rules-k8s
  gcloud config set compute/zone us-central1-f
  gcloud container clusters get-credentials testing
fi
# Check our installs.
bazel version
gcloud version
kubectl version

# Check that all of our tools and samples build
bazel clean && bazel build //...
# Check that all of our tests pass
bazel clean && bazel test //...

# Run end-to-end integration testing.
# First, GRPC.
./examples/hellogrpc/e2e-test.sh cc java go py
# Second, HTTP.
./examples/hellohttp/e2e-test.sh java go py nodejs
# Third, TODO Controller.
./examples/todocontroller/e2e-test.sh py
