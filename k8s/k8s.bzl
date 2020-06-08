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
"""Rules for manipulation of K8s constructs."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//toolchains/kubectl:kubectl_configure.bzl", "kubectl_configure")
load(":with-defaults.bzl", _k8s_defaults = "k8s_defaults")

k8s_defaults = _k8s_defaults

def k8s_repositories():
    """Download dependencies of k8s rules."""

    excludes = native.existing_rules().keys()

    if "com_github_yaml_pyyaml" not in excludes:
        # Used by utilities for roundtripping yaml.
        http_archive(
            name = "com_github_yaml_pyyaml",
            build_file_content = """
py_library(
    name = "yaml",
    srcs = glob(["lib/yaml/*.py"]),
    imports = [
        "lib",
    ],
    visibility = ["//visibility:public"],
)

py_library(
    name = "yaml3",
    srcs = glob(["lib3/yaml/*.py"]),
    imports = [
        "lib3",
    ],
    visibility = ["//visibility:public"],
)
""",
            sha256 = "e9df8412ddabc9c21b4437ee138875b95ebb32c25f07f962439e16005152e00e",
            strip_prefix = "pyyaml-5.1.2",
            urls = ["https://github.com/yaml/pyyaml/archive/5.1.2.zip"],
        )

    # Register the default kubectl toolchain targets for supported platforms
    # note these work with the autoconfigured toolchain
    native.register_toolchains(
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_windows_toolchain",
    )
    if "io_bazel_rules_go" not in excludes:
        http_archive(
            name = "io_bazel_rules_go",
            sha256 = "7b9bbe3ea1fccb46dcfa6c3f3e29ba7ec740d8733370e21cdc8937467b4a4349",
            urls = [
                "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.22.4/rules_go-v0.22.4.tar.gz",
                "https://github.com/bazelbuild/rules_go/releases/download/v0.22.4/rules_go-v0.22.4.tar.gz",
            ],
        )
    if "bazel_gazelle" not in excludes:
        http_archive(
            name = "bazel_gazelle",
            sha256 = "cdb02a887a7187ea4d5a27452311a75ed8637379a1287d8eeb952138ea485f7d",
            urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz"],
        )
    if "io_bazel_rules_docker" not in excludes:
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "3efbd23e195727a67f87b2a04fb4388cc7a11a0c0c2cf33eec225fb8ffbb27ea",
            strip_prefix = "rules_docker-0.14.2",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.2/rules_docker-v0.14.2.tar.gz"],
        )
    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            sha256 = "e5d90f0ec952883d56747b7604e2a15ee36e288bb556c3d0ed33e818a4d971f2",
            strip_prefix = "bazel-skylib-1.0.2",
            urls = ["https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.tar.gz"],
        )
    if "k8s_config" not in excludes:
        # WORKSPACE target to configure the kubectl tool
        kubectl_configure(name = "k8s_config", build_srcs = False)
