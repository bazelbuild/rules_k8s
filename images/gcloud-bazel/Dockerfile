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

FROM ubuntu:18.04
# Based off github.com/kubernetes/test-infra/images/bazelbuild
LABEL maintainer="fejta@google.com"

# See https://docs.bazel.build/versions/main/install-ubuntu.html
RUN apt update \
    && apt install -y --no-install-recommends \
       gnupg \
       ca-certificates
COPY bazel.pub.gpg bazel.list /
RUN gpg -o /etc/apt/trusted.gpg.d/bazel.gpg --dearmor /bazel.pub.gpg \
    && rm /bazel.pub.gpg \
    && mv /bazel.list /etc/apt/sources.list.d/bazel.list

ARG NEW_VERSION
ARG OLD_VERSION
RUN apt update \
    && apt install -y --no-install-recommends \
       "bazel-${NEW_VERSION}" \
       "bazel-${OLD_VERSION}"
   

# See the following docs:
# * https://cloud.google.com/sdk/docs/install#deb

# Ensure new repos aren't compromised.
COPY gcloud.pub.gpg /
RUN apt-key --keyring /usr/share/keyrings/cloud.google.gpg add /gcloud.pub.gpg \
    && rm /gcloud.pub.gpg

# Add new repos to install google-cloud-sdk (including kubectl)
COPY sources.list /etc/apt/sources.list.d/google-cloud-sdk.list

# Install necessary dependencies:
# * gcloud: needed by rules_go and test-e2e.sh
# * kubectl: needed by rules_k8s
# * pip setuptools wheel: needed by python rules
# * python-pip: needed by python rules
RUN apt update \
    && apt install -y --no-install-recommends \
      google-cloud-sdk \
      kubectl \
      python-pip \
    && apt-get clean \
    && pip install pip setuptools wheel
