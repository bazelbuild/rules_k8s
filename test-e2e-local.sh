#!/usr/bin/env bash

# Copyright 2018 The Bazel Authors. All rights reserved.
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

# This file runs all rules_k8s e2e tests locally.
# It confirms that the platform running this script is Linux and verifies that
# all the required tools are installed. Then it builds and tests all the Bazel
# targets in the rules_k8s project, creates the Kubernetes namespace for the
# tests and runs all tests.

set -o errexit
set -o nounset
set -o xtrace

check-plat() {
  local plat="$(uname -s)"
  if [[ $plat != Linux ]]; then
    echo "System must be Linux, found: $plat" >&2
    return 1
  fi
}

check-plat

# Check installs.
bazel version
docker version
kubectl version
minikube version

# Don't build/test the prow image
EXCLUDED_TARGETS="-//images/gcloud-bazel:gcloud_install -//images/gcloud-bazel:gcloud_push"

# Check that all of our tools and samples build
bazel build -- //... $EXCLUDED_TARGETS
bazel test  -- //... $EXCLUDED_TARGETS

# Create namespace for this job
E2E_NAMESPACE="rules-k8s-e2e-test"

kubectl get "namespaces/${E2E_NAMESPACE}" &> /dev/null || kubectl create namespace "${E2E_NAMESPACE}"

delete() {
    # Delete the namespace
    echo "Deleting kubernetes namespace ${E2E_NAMESPACE}"
    # Delete the namespace
    kubectl delete namespaces/$E2E_NAMESPACE
}

# Setup a trap to delete the namespace on error
set +o xtrace
trap "echo FAILED, cleaning up...; delete" EXIT
set -o xtrace

# Run end-to-end integration testing.
# First, GRPC.
./examples/hellogrpc/e2e-test.sh local $E2E_NAMESPACE cc java go py
# Second, HTTP.
./examples/hellohttp/e2e-test.sh local $E2E_NAMESPACE java go py nodejs

# Delete everything as we are now done
delete

# Replace the exit trap with a pass message
trap "echo PASS" EXIT
