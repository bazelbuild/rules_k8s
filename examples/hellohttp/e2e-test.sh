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

source ./examples/util.sh

validate_args $@
shift 2

fail() {
    echo "FAILURE: $1"
    exit 1
}

CONTAINS() {
    local complete="$1"
    local substring="$2"

    echo "$complete" | grep -Fsq -- "$substring" >/dev/null
}

EXPECT_CONTAINS() {
    local complete="$1"
    local substring="$2"
    local message="${3:-Expected '$substring' not found in '$complete'}"

    CONTAINS "$complete" "$substring" || fail "$message"
}

# Ensure there is an ip address for hello-http-staging:8080
apply-lb() {
    logfail bazel run examples/hellohttp:staging-service.apply
}

check_msg() {
    echo -n "IP: "
    local ip
    while true; do
        ip=$(get_lb_ip $local hello-http-staging)
        if [[ -n "$ip" ]]; then
            echo "$ip"
            break
        fi
        echo -n .
        sleep 5
    done

    local output
    local url="http://$ip:8080"
    echo -n "curl $url: "
    for i in {1..5}; do
        if output=$(curl "$url" 2>/dev/null); then
            echo "$output"
            break
        fi
        echo -n "."
        sleep 10
    done
    if [[ -z "$output" ]]; then
        output=$(curl --fail "$url" 2>/dev/null)
    fi

    if ! echo "${output}" | grep "DEMO$1[ ]" &>/dev/null; then
        echo "wanted DEMO$1[ ], not in $output" >&2
        return 1
    fi
}

edit() {
    logfail "./examples/hellohttp/$1/edit.sh" "$2"
}

apply() {
    logfail bazel run "examples/hellohttp/$1:staging.apply"
}

delete() {
    logfail kubectl get all --namespace="${namespace}" --selector=app=hello-http-staging
    logfail bazel run "examples/hellohttp/$1:staging.describe"
    logfail bazel run "examples/hellohttp/$1:staging.delete"
}

check_bad_substitution() {
    if ! bazel run examples/hellohttp:error-on-run &>/dev/null; then
      return 0
    else
      echo "Bad substitution should fail!"
      exit 1
    fi
}

check_no_images_resolution() {
    logfail bazel build examples/hellohttp:resolve-external
    bazel-bin/examples/hellohttp/resolve-external 2>/dev/null | grep "[/]pause[@]" >/dev/null
}

# e2e test that checks that args are added to the kubectl apply command
check_kubectl_args() {
    # Checks that bazel run <some target> does pick up the args attr and
    # passes it to the execution of the template
    EXPECT_CONTAINS "$(bazel run examples/hellohttp/java:staging.apply 2>/dev/null)" "apply --v=2"
    # Checks that bazel run <some target> -- <some extra arg> does pass both the
    # args in the attr as well as the <some extra arg> to the execution of the
    # template
    EXPECT_CONTAINS "$(bazel run examples/hellohttp/java:staging.apply -- --v=1 2>/dev/null)" "apply --v=2 --v=1"
}

logfail() {
    echo "++ $@"
    local out
    local code
    out=$("$@" 2>&1) && return 0 || code=$?
    echo "++ FAIL: $code=$@" >&2
    echo "$out"
    return $code
}

main() {
    echo "hellohttp: setup"
    trap "echo FAILED: hellohttp >&2" EXIT
    local failed=()
    check_bad_substitution
    check_no_images_resolution
    check_kubectl_args
    apply-lb

    # Test each requested language
    while [[ -n "${1:-}" ]]; do
        local lang=$1
        shift
        case "$lang" in
          cc)
            echo "hellohttp/$lang: skip (not implemented)"
            continue
            ;;
        esac
        echo "hellohttp/$lang: start"

        trap "echo hellohttp/$lang: FAIL >&2" EXIT
        for want in $RANDOM $RANDOM; do
          edit "$lang" "$want"
          apply "$lang"
          sleep 25s
          check_msg "$want"
        done
        delete "$lang"
        echo "hellohttp/$lang: PASS"
    done
    trap - EXIT
}

main "$@"
echo "hellohttp: PASS"
