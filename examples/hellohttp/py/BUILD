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

load("@py_deps//:requirements.bzl", "all_requirements")
load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")
load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

py3_image(
    name = "server",
    srcs = ["server.py"],
    main = "server.py",
    deps = all_requirements,
)

k8s_deploy(
    name = "staging",
    images = {
        "hello-http-image:latest": ":server",
    },
    template = "//examples/hellohttp:deployment.yaml",
)
