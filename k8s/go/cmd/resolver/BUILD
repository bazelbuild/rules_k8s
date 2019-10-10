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

load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

package(default_visibility = ["//visibility:private"])

licenses(["notice"])  # Apache 2.0

go_library(
    name = "go_default_library",
    srcs = ["resolver.go"],
    importpath = "github.com/bazelbuild/rules_k8s/k8s/go/cmd/resolver",
    visibility = ["//visibility:private"],
    deps = [
        "@io_bazel_rules_docker//container/go/pkg/compat:go_default_library",
        "@io_bazel_rules_docker//container/go/pkg/utils:go_default_library",
        "@com_github_google_go_containerregistry//pkg/authn:go_default_library",
        "@com_github_google_go_containerregistry//pkg/name:go_default_library",
        "@com_github_google_go_containerregistry//pkg/v1/remote:go_default_library",
    ],
)

go_binary(
    name = "resolver",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
