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
package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

load("@io_bazel_rules_docker//nodejs:image.bzl", "nodejs_image")

nodejs_image(
    name = "server",
    data = [":server.js"],
    entry_point = "io_bazel_rules_k8s/examples/hellohttp/nodejs/server.js",
    node_modules = "@examples_hellohttp_npm//:node_modules",
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging-deployment",
    images = {
        "hello-http-image": ":server",
    },
    template = "//examples/hellohttp:deployment.yaml",
)

load("@k8s_service//:defaults.bzl", "k8s_service")

k8s_service(
    name = "staging-service",
    template = "//examples/hellohttp:service.yaml",
)

load("@io_bazel_rules_k8s//k8s:objects.bzl", "k8s_objects")

k8s_objects(
    name = "staging",
    objects = [
        ":staging-deployment",
        ":staging-service",
    ],
)
