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

function guess_runfiles() {
    pushd "${BASH_SOURCE[0]}.runfiles" > /dev/null 2>&1
    pwd
    popd > /dev/null 2>&1
}

RUNFILES="${PYTHON_RUNFILES:-$(guess_runfiles)}"

TMP_YAML=$(mktemp)
trap "rm ${TMP_YAML}" EXIT

PYTHON_RUNFILES=${RUNFILES} %{resolve_script} > "$TMP_YAML"

kubectl --cluster="%{cluster}" %{namespace_arg} replace -f "$TMP_YAML" "$@"

ROLLOUT_STATUS="%{wait_for_rollout}"
if [ "${ROLLOUT_STATUS}" == "True" ]; then
    RESOURCE_NAMES=$(kubectl --cluster="%{cluster}" %{namespace_arg} get -f "$TMP_YAML" --output=name)
    declare -a resource_types=("deployment.apps" "statefulset.apps")
    for resource_type in "${resource_types[@]}"; do
        if grep -q "${resource_type}/" <<< "$RESOURCE_NAMES"; then
            grep "${resource_type}/" <<< "$RESOURCE_NAMES" | while read -r RESOURCE_NAME; do
                kubectl --cluster="%{cluster}" %{namespace_arg} rollout status "${RESOURCE_NAME}" "$@"
            done
        fi
    done
fi
