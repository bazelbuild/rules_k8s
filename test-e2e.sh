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
set -o pipefail

delete-all() {
    # Delete the namespace
    log kubectl delete all -n "$E2E_NAMESPACE" --all
    log kubectl delete namespaces/$E2E_NAMESPACE
}

log() {
    (
        set -o xtrace
        "$@"
    )
}

ensure-docker() {
  if grep gcr.io "$HOME/.docker/config.json" &>/dev/null; then
      echo "docker: already configured"
  else
      gcloud auth configure-docker --quiet
  fi
}

ensure-gcloud() {
    if [[ -n "${GOOGLE_JSON_KEY:-}" ]]; then
      # Log into gcloud
      echo -n "${GOOGLE_JSON_KEY}" > keyfile.json
      gcloud auth activate-service-account --key-file keyfile.json >/dev/null
      rm -f keyfile.json
    fi

    # Setup our credentials
    logfail gcloud container clusters get-credentials testing --project=rules-k8s --zone=us-central1-f
}

fail() {
    echo "test-e2e.sh: FAIL, cleaning up..." >&2
    echo "=============== VERSION INFO ===========" >&2
    log bazel version >&2
    log gcloud version >&2
    log kubectl version >&2

    echo "========== CLEAN UP ==========="
    delete-all || echo "cleanup failed" >&2
    echo "test-e2e.sh: FAIL" >&2
    return 1
}


logfail() {
    echo "+ $@" >&2
    local out
    local code
    out=$("$@" 2>&1) && return 0 || code=$?
    echo "$out"
    return $code
}

main() {
    echo "Test languages: $@" >&2

    ensure-docker
    ensure-gcloud

    # Check that all of our tools and samples build and pass unit test.
    logfail bazel test -- //... -//images/gcloud-bazel:gcloud_install -//images/gcloud-bazel:gcloud_push

    # Run the garbage collection script to delete old namespaces.
    logfail bazel run -- //examples:e2e_gc

    # Create a unique namespace for this job using the repo name and the build id
    export E2E_NAMESPACE="build-${BUILD_ID:-$USER}"
    if kubectl get "namespaces/${E2E_NAMESPACE}" &> /dev/null; then
        echo "$E2E_NAMESPACE already exists"
    else
        log kubectl create namespace "${E2E_NAMESPACE}" >/dev/null
    fi

    trap fail EXIT
    local failed=()
    log ./examples/resolver/e2e-test.sh remote "$E2E_NAMESPACE" "$@" || failed+=(resolver)
    log ./examples/hellogrpc/e2e-test.sh remote "$E2E_NAMESPACE" "$@" || failed+=(hellogrpc)
    log ./examples/hellohttp/e2e-test.sh remote "$E2E_NAMESPACE" "$@" || failed+=(hellohttp)
    if [[ "${#failed[@]}" -gt 0 ]]; then
        echo "FAIL: test-e2e.sh: ${failed[@]}"
        return 1
    fi
    trap - EXIT
    echo "Tests pass, cleaning up..."
    delete-all || (echo "test-e2e.sh: cleanup failed" >&2; return 1)
}

if [[ $# == 0 ]]; then
    echo "Usage: $(basename "$0") go [java nodejs]"
    main go java nodejs
else
    main "$@"
fi
echo "test-e2e.sh: PASS"
