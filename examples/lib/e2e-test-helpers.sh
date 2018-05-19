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

function get_lb_ip() {
  SERVICE_NAME="$1"

  NOW=$(date +%s)
  # It can take a surprisingly long time for k8s to provision an external IP
  TIMEOUT_EPOCH=$((NOW + 60 * 2))
  until [ "$(date +%s)" -ge "$TIMEOUT_EPOCH" ];  do
    LB_IP="$(kubectl --namespace="${USER}" get service "$SERVICE_NAME" \
          -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
    if [ "$LB_IP" == "" ]; then
      1>&2 echo "Still waiting for external IP..."
      sleep 5
    else
      1>&2 echo "External IP: $LB_IP"
      echo "$LB_IP"
      return
    fi
  done

  1>&2 echo "Could not get external IP, and out of retries"
  exit 1
}

function check_msg() {
  CMD="$1"          # What executable to run
  FMT="$2"          # Argument to $CMD. %s gets replaced with the load balancer IP address
  SERVICE_NAME="$3" # What Service's IP to discover
  MATCH_STR="$4"    # What string to grep for in the response

  echo Checking that the response from service: "${SERVICE_NAME}" matches: "DEMO$MATCH_STR<space>"
  LB_IP="$(get_lb_ip $SERVICE_NAME)"

  NOW=$(date +%s)
  # Give new servers time to spin up.
  # The java grpc server is especially slow.
  TIMEOUT_EPOCH=$((NOW + 60 * 5))
  until [ "$(date +%s)" -ge "$TIMEOUT_EPOCH" ];  do
    OUTPUT=$(timeout 1s "$CMD" $(printf "$FMT" "$LB_IP") || true)
    if echo "$OUTPUT" | grep "DEMO$MATCH_STR[ ]"; then
      1>&2 echo "Matched DEMO$MATCH_STR<space> in output"
      return
    else
      1>&2 echo "Mismatch: $OUTPUT != DEMO$MATCH_STR<space>"
      1>&2 echo "Still waiting for a match..."
      sleep 5
    fi
  done

  1>&2 echo "Could not find a match, and out of retries"
  exit 1
}
