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

# Function to validate the input args for the e2e-test.sh scripts.
function validate_args() {
  if [[ -z "${1:-}" ]]; then
    echo "ERROR: None of execution type, kubernetes namspace and languages is provided!"
    echo "Usage: $(basename $0) <'remote' or 'local' run> <kubernetes namespace> <language ...>"
    exit 1
  fi

  local=false
  if [[ "$1" == "local" ]]; then
    local=true
  elif [[ "$1" != "remote" ]]; then
    echo "ERROR: Execution type must be either 'remote' or 'local'!"
    echo "Usage: $(basename $0) <'remote' or 'local' run> <kubernetes namespace> <language ...>"
    exit 1
  fi
  shift

  if [[ -z "${1:-}" ]]; then
    echo "ERROR: None of kubernetes namspace and languages is provided!"
    echo "Usage: $(basename $0) <'remote' or 'local' run> <kubernetes namespace> <language ...>"
    exit 1
  fi
  namespace="$1"
  shift
  if [[ -z "${1:-}" ]]; then
    echo "ERROR: Languages not provided!"
    echo "Usage: $(basename $0) <'remote' or 'local' run> <kubernetes namespace> <language ...>"
    exit 1
  fi
}

# Function to get the Kubernetes load balancer service IP address.
# Usage when running a cluster in minikube:
#   get_lb_ip true <service name>
# Usage when running a cluster on GKE:
#   get_lb_ip false <service name>
function get_lb_ip() {
  # Determine the location of variable to retrieve the service IP address
  # based on execution type
  ip_var='{.status.loadBalancer.ingress[0].ip}'
  if $1; then
    ip_var='{.spec.clusterIP}'
  fi

  kubectl --namespace="${namespace}" get service $2 \
    -o jsonpath=$ip_var
}
