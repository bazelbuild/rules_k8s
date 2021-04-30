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

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
    SED=gsed
fi
if ! command -v "$SED" >/dev/null; then
    echo "Please install $SED" >&2
    exit 1
fi
export SED

# validate_args set namespace and validates languages are set are set.
validate_args() {
  if [[ -z "${1:-}" ]]; then
    echo "ERROR: None of execution type, kubernetes namspace and languages is provided!"
    echo "Usage: $(basename $0) <kubernetes namespace> <language ...>"
    exit 1
  fi

  if [[ -z "${1:-}" ]]; then
    echo "ERROR: None of kubernetes namspace and languages is provided!"
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
}

# port-forward forwards ports from a service to localhost.
# Usage:
#   port-forward <service name> <port(s)> # see kubectl help port-forward
port-forward() {
  kubectl --namespace="${namespace}" port-forward --address=localhost "service/$1" "${@:2}" >/dev/null &
}

# stop-port-forwarding kills all port forwarding jobs
stop-port-forwarding() {
    local jobs=$(jobs -p kubectl 2>/dev/null || true)
    if [[ -z "$jobs" ]]; then
        return 0
    fi
    echo "Stop port forwarding: kill $jobs"
    kill $jobs
}
