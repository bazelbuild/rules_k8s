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

load("@io_bazel_rules_docker//docker/contrib/cc:image.bzl", "cc_image")

cc_image(
    name = "server",
    srcs = ["main.cc"],
    deps = ["//examples/hello-grpc/proto"],
)

load("@io_bazel_rules_docker//docker:docker.bzl", "docker_push")

docker_push(
    name = "push",
    image = ":server",
    registry = "us.gcr.io",
    repository = "rules_k8s/examples/hello-grpc",
    tag = "cc",
)
