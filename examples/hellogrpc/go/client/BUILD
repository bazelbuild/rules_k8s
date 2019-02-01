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

load("@io_bazel_rules_go//go:def.bzl", "go_binary")

package(default_visibility = ["//visibility:public"])

go_binary(
    name = "client_bin",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/rules_k8s/rules_k8s/examples/hellogrpc/go/client",
    deps = [
        "//examples/hellogrpc/proto:simple_go_grpc",
        "@org_golang_google_grpc//:go_default_library",
    ],
)

# Normalize the binary name per
# https://github.com/bazelbuild/rules_go/issues/1239#issuecomment-361296415
genrule(
    name = "client_exe",
    srcs = [":client_bin"],
    outs = ["client"],
    cmd = "cp $(SRCS) $@",
    output_to_bindir = True,
)
