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

load("@build_stack_rules_proto//cpp:cpp_grpc_library.bzl", "cpp_grpc_library")
load("@build_stack_rules_proto//go:go_grpc_library.bzl", "go_grpc_library")
load("@build_stack_rules_proto//java:java_grpc_library.bzl", "java_grpc_library")
load("@build_stack_rules_proto//python:python_grpc_library.bzl", "python_grpc_library")

proto_library(
    name = "simple_proto",
    srcs = ["simple.proto"],
    visibility = ["//visibility:public"],
)

cpp_grpc_library(
    name = "simple_cc_grpc",
    visibility = ["//examples/hellogrpc/cc:__subpackages__"],
    deps = [":simple_proto"],
)

java_grpc_library(
    name = "simple_java_grpc",
    visibility = ["//examples/hellogrpc/java:__subpackages__"],
    deps = [":simple_proto"],
)

go_grpc_library(
    name = "simple_go_grpc",
    go_deps = [
        "@org_golang_google_grpc//codes:go_default_library",
        "@org_golang_google_grpc//status:go_default_library",
    ],
    importpath = "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go",
    visibility = ["//examples/hellogrpc/go:__subpackages__"],
    deps = [":simple_proto"],
)

python_grpc_library(
    name = "simple_python_grpc",
    visibility = ["//examples/hellogrpc/py:__subpackages__"],
    deps = [":simple_proto"],
)
