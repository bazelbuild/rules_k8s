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

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

k8s_deploy(
    name = "staging",
    template = "deployment.yaml",
)

k8s_deploy(
    name = "staging-service",
    template = "service.yaml",
)

# This is used by the e2e testing to make sure that we get a clear
# failure when a reference isn't substituted.
k8s_deploy(
    name = "error-on-run",
    images = {
        # Simulate a typo
        "hello-http_image:latest": "//examples/hellohttp/go:server",
    },
    template = "deployment.yaml",
)

# This is used by the e2e testing to make sure that we resolve
# image names that are external to our build process.
k8s_deploy(
    name = "resolve-external",
    template = "static-deployment.yaml",
)
