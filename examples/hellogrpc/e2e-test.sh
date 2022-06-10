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

validate_args "$@"
shift 1

fail() {
    echo "FAILURE: $@"
    exit 1
}

CONTAINS() {
    local complete=$1
    local substring=$2

    echo "$complete" | grep -Fsq -- "$substring" >/dev/null
}

EXPECT_CONTAINS() {
    local complete="$1"
    local substring="$2"
    local message="${3:-Expected '$substring' not found in '$complete'}"

    CONTAINS "$complete" "$substring" || fail "$message"
}

CONTAINS_PATTERN() {
    local complete=$1
    local substring=$2

    echo "$complete" | grep -Esq -- "$substring" >/dev/null
}

EXPECT_CONTAINS_PATTERN() {
    local complete=$1
    local substring=$2
    local message="${3:-Expected '$substring' not found in '$complete'}"

    CONTAINS_PATTERN "$complete" "$substring" || fail "$message"
}

# Ensure there is an ip address for hell-grpc-staging:50051
apply-lb() {
    # We use `bazel build ... && bazel-bin/...` here in this file instead of
    # `bazel run` directly in order to make sure that direct execution of the
    # built output works as well
    logfail "$bazel" build examples/hellogrpc:staging-service.apply
    logfail bazel-bin/examples/hellogrpc/staging-service.apply
}

resolve() {
    logfail "$bazel" build "examples/hellogrpc/$1/server:staging.resolve"
    logfail "bazel-bin/examples/hellogrpc/$1/server/staging.resolve"
}

create() {
    logfail "$bazel" build "examples/hellogrpc/$1/server:staging.create"
    logfail "bazel-bin/examples/hellogrpc/$1/server/staging.create"
}

check_msg() {
    logfail "$bazel" build "examples/hellogrpc/$1/client"

    stop-port-forwarding
    port-forward hello-grpc-staging 50051
    local ip="localhost"
    echo "IP: $ip"

    # Make Bazel generate a temporary script that runs the client executable
    # This will only generate the temp executable. It won't actually run it.
    local output
    local tmp_exec=hellogrpc_$1_client
    logfail "$bazel" run "//examples/hellogrpc/$1/client" "--script_path=$tmp_exec"

    echo -n "$tmp_exec: "
    # the service may not be up immediately after ip allocation so retry a few times
    for i in {1..5}; do
        if output=$("./$tmp_exec" "$ip" 2>/dev/null); then
            echo "got: $output"
            break
        fi
        echo -n "."
        sleep 10
    done

    if [[ -z "$output" ]]; then
        output=$(./${tmp_exec} "$ip")
    fi

    rm "$tmp_exec"
    want=$2
    if ! echo "$output" | grep "DEMO${want}[ ]" &>/dev/null; then
        echo "wanted DEMO${want}[ ], not in $output" >&2
        return 1
    fi
}

edit() {
    logfail "./examples/hellogrpc/$1/server/edit.sh" "$2"
}

diff() {
    logfail "$bazel" build "examples/hellogrpc/$1/server:staging.diff"
    # We want diff to return 1 so we can't use logfail here
    cmd="bazel-bin/examples/hellogrpc/$1/server/staging.diff"
    echo "++ $cmd"
    local out
    local code
    out=$("$cmd" 2>&1) && code=0 || code=$?
    if [ $code -eq 1 ]; then
        return 0
    elif [ $code -eq 0 ]; then
        echo "++ DIFF FOUND NO CHANGES: $cmd" >&2
        echo "$out"
        # We can't just return $code here, since it would be a "success"
        return 1
    else
        echo "++ FAIL: $code=$cmd" >&2
        echo "$out"
        return $code
    fi
}

update() {
    logfail "$bazel" build "examples/hellogrpc/$1/server:staging.replace"
    logfail "bazel-bin/examples/hellogrpc/$1/server/staging.replace"
}

delete() {
    logfail kubectl get all --namespace="${namespace}" --selector=app=hello-grpc-staging
    logfail "$bazel" build "examples/hellogrpc/$1/server:staging.describe"
    logfail "bazel-bin/examples/hellogrpc/$1/server/staging.describe" || echo "$1 describe: hellogrpc server not found" >&2
    logfail "$bazel" build "examples/hellogrpc/$1/server:staging.delete"
    logfail "bazel-bin/examples/hellogrpc/$1/server/staging.delete"
}

check_kubeconfig_args() {
    for cmd in apply delete; do
        logfail "$bazel" build examples/hellogrpc:staging-deployment-with-kubeconfig.${cmd}
        OUTPUT="$(cat ./bazel-bin/examples/hellogrpc/staging-deployment-with-kubeconfig.${cmd})"
        EXPECT_CONTAINS_PATTERN "$OUTPUT" "--kubeconfig=\S*/examples/hellogrpc/kubeconfig.out"
    done
}

# e2e test that checks that args are added to the kubectl apply command
check_kubectl_args() {
    # Checks that bazel run <some target> does pick up the args attr and
    # passes it to the execution of the template
    EXPECT_CONTAINS "$("$bazel" run examples/hellogrpc:staging.apply 2>/dev/null)" "apply --v=2"
    # Checks that bazel run <some target> -- <some extra arg> does pass both the
    # args in the attr as well as the <some extra arg> to the execution of the
    # template
    EXPECT_CONTAINS "$("$bazel" run examples/hellogrpc:staging.apply -- --v=1 2>/dev/null)" "apply --v=2 --v=1"
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

fail-lang() {
    stop-port-forwarding
    echo "hellogrpc/$lang: FAIL" >&2
}

main() {
    echo "hellogrpc: setup"
    trap "echo hellogrpc: FAILED" EXIT
    local failed=()
    check_kubeconfig_args
    check_kubectl_args
    apply-lb
    trap stop-port-forwarding EXIT

    while [[ -n "${1:-}" ]]; do
        lang=$1
        shift
        case "$lang" in
          nodejs)
            echo "hellogrpc/$lang: skip (not implemented)"
            continue
            ;;
        esac
        echo "hellogrpc/$lang: start"

        delete "$lang" &> /dev/null || true
        trap "fail-lang $lang" EXIT
        local want
        want="$RANDOM"
        edit "$lang" "$want"
        resolve "$lang"
        create "$lang"
        sleep 25
        check_msg "$lang" "$want"
        want="$RANDOM"
        edit "$lang" "$want"
        diff "$lang"
        update "$lang"
        sleep 25 # Mitigate against slow startup
        check_msg "$lang" "$want"
        delete "$lang"
        echo "hellogrpc/$lang: PASS"
    done
    trap stop-port-forwarding EXIT
}

main "$@"
echo "hellogrpc: PASS"
