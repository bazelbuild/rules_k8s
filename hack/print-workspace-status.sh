#!/bin/bash
# Copyright 2017 The Bazel Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

cat <<EOF
STABLE_DOCKER_REPO ${DOCKER_REPO_OVERRIDE:-us.gcr.io/rules_k8s}
STABLE_BUILD_CLUSTER ${BUILD_CLUSTER_OVERRIDE:-gke_rules-k8s_us-central1-f_testing}
EOF
