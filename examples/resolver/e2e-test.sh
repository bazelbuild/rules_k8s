#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source ./examples/util.sh

validate_args $@
shift 2

apply() {
    logfail bazel run "examples/resolver:example.apply"
}

check_object_exists() {
    # The name of the configmap, resolved, is determined by the resolver
    logfail kubectl get cm --namespace="${namespace}" resolved
}

delete() {
    logfail bazel run "examples/resolver:example.delete"
}

check_object_deleted() {
    # The resolver should also run on delete, so the configmap should be gone now
    if ! kubectl delete cm --namespace="${namespace}" resolved &>/dev/null; then
        return 0
    else
        echo "++ FAIL: Expected configmap to be deleted"
    fi
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
    echo "resolver: start"
    trap "echo FAILED: resolver >&2" EXIT

    apply
    sleep 3s
    check_object_exists
    delete
    sleep 3s
    check_object_deleted
    
    trap - EXIT
}

main "$@"
echo "resolver: PASS"
