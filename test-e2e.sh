#!/usr/bin/env bash

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
set -o xtrace

# Helper command for local debugging.
# Note: prow jobs already run inside a container
run-in-container() {
  cd "$(dirname "${BASH_SOURCE}")"
  echo "startup --host_jvm_args=-Duser.name=$USER" > /tmp/test-e2e.bazelrc
  args=(
    # Ensure we do not deploy to namespace root
    # But don't use -u $(id -u) as this is a pain
    -e "USER=$USER"
    -v /tmp/test-e2e.bazelrc:/root/.bazelrc
    # Map rules_k8s repo into /workspace
    -v "$PWD":/workspace
    -w /workspace
    # Map in credentials
    -v "$HOME/.kube":/root/.kube
    -v "$HOME/.config/gcloud":/root/.config/gcloud
    # Remove image after completion
    --rm=true gcr.io/rules-k8s/gcloud-bazel:latest-"$USER"
    # Run this script
    "./$(basename "${BASH_SOURCE}")"
  )

  docker run "${args[@]}" "$@"
  exit 0
}

if [[ "${1:-}" == "--container" ]]; then
  shift
  run-in-container "$@"
fi

check-plat() {
  local plat="$(uname -s)"
  if [[ $plat != Linux ]]; then
    echo "Consider using --container" >&2
    echo "System must be Linux, found: $plat" >&2
    return 1
  fi
}

check-plat

set +o xtrace
export CLOUDSDK_CONTAINER_USE_CLIENT_CERTIFICATE=True
if [[ -n "${GOOGLE_JSON_KEY:-}" ]]; then
  # Log into gcloud
  echo -n "${GOOGLE_JSON_KEY}" > keyfile.json
  gcloud auth activate-service-account --key-file keyfile.json
  rm -f keyfile.json
fi
set -o xtrace

# Setup our credentials
gcloud container clusters get-credentials testing --project=rules-k8s --zone=us-central1-f
gcloud auth configure-docker --quiet

# Check our installs.
bazel version
gcloud version
kubectl version

# Check that all of our tools and samples build
bazel build //...
bazel test //...

# Run end-to-end integration testing.
# First, GRPC.
./examples/hellogrpc/e2e-test.sh cc java go py
# Second, HTTP.
./examples/hellohttp/e2e-test.sh java go py nodejs
# Third, TODO Controller.
./examples/todocontroller/e2e-test.sh py
