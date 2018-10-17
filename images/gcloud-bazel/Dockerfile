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

# Ubuntu with bazel, gcloud and its dependencies preinstalled.

FROM launcher.gcr.io/google/bazel:latest
# Based off github.com/kubernetes/test-infra/images/bazelbuild
LABEL maintainer="fejta@google.com"

# See the following docs:
# * https://docs.bazel.build/versions/master/install-ubuntu.html
# * https://cloud.google.com/sdk/docs/downloads-apt-get

# Ensure new repos aren't compromised.
COPY gcloud.pub.gpg /
RUN apt-key add /gcloud.pub.gpg \
    && rm /gcloud.pub.gpg

# Add new repos to install bazel and google-cloud-sdk (including kubectl)
COPY sources.list /etc/apt/sources.list.d/gcloud.list

# Install necessary dependencies:
# * gcloud: needed by rules_go and test-e2e.sh
# * kubectl: needed by rules_k8s
# * pip setuptools wheel: needed by python rules
# * python-pip: needed by python rules
RUN apt-get update && apt-get install -y --no-install-recommends \
    google-cloud-sdk \
    kubectl \
    python-pip \
    && apt-get clean \
    && python -m pip install --upgrade pip setuptools wheel
