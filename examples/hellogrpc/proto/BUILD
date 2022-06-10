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

load("@rules_proto_grpc//go:go_grpc_library.bzl", "go_grpc_library")
load("@rules_proto_grpc//java:defs.bzl", "java_grpc_library")
load("@rules_proto//proto:defs.bzl", "proto_library")
load("@io_bazel_rules_go//proto:def.bzl", "go_proto_library")

proto_library(
    name = "simple_proto",
    srcs = ["simple.proto"],
    visibility = ["//visibility:public"],
)

java_grpc_library(
    name = "simple_java_grpc",
    visibility = ["//examples/hellogrpc/java:__subpackages__"],
    protos = [":simple_proto"],
)

go_grpc_library(
    name = "simple_go_grpc",
    importpath = "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go",
    visibility = ["//examples/hellogrpc/go:__subpackages__"],
    protos = [":simple_proto"],
)
