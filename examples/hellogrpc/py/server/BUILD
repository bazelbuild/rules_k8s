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

load("@examples_helloworld_pip//:requirements.bzl", "requirement")
load("@io_bazel_rules_docker//python:image.bzl", "py_image")

py_image(
    name = "server",
    srcs = ["server.py"],
    # "layers" is just like "deps", but it also moves the dependencies each into
    # their own layer, which can dramatically improve developer cycle time.  For
    # example here, the grpcio layer is ~40MB, but the rest of the app is only
    # ~400KB.  By partitioning things this way, the large grpcio layer remains
    # unchanging and we can reduce the amount of image data we repush by ~99%!
    layers = [
        requirement("setuptools"),
        "//examples/hellogrpc/proto:simple_python_grpc",
    ],
    main = "server.py",
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging",
    images = {
        "us.gcr.io/not-my-project/hello-grpc:staging": ":server",
    },
    template = "//examples/hellogrpc:deployment.yaml",
)
