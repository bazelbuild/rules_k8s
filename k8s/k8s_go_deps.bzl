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
"""Macro to load Go package dependencies of Go binaries in this repository."""

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load(
    "@io_bazel_rules_docker//repositories:go_repositories.bzl",
    rules_docker_go_deps = "go_deps",
)
load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    rules_docker_repositories = "repositories",
)
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

def deps():
    """Import dependencies for Go binaries in rules_k8s.

       This macro assumes k8s_repositories in //k8s:k8s.bzl has been called
       already.
    """
    go_rules_dependencies()
    go_register_toolchains()
    gazelle_dependencies()
    rules_docker_repositories()
    rules_docker_go_deps()

    maybe(
        go_repository,
        name = "com_github_google_go_cmp",
        importpath = "github.com/google/go-cmp",
        sum = "h1:Xye71clBPdm5HgqGwUkwhbynsUJZhDbS20FvLhQ2izg=",
        version = "v0.3.1",
    )
