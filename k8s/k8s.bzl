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
)""",
            sha256 = "6b4314b1b2051ddb9d4fcd1634e1fa9c1bb4012954273c9ff3ef689f6ec6c93e",
            strip_prefix = "pyyaml-3.12",
            urls = ["https://github.com/yaml/pyyaml/archive/3.12.zip"],
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
            sha256 = "513c12397db1bc9aa46dd62f02dd94b49a9b5d17444d49b5a04c5a89f3053c1c",
            urls = [
                "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.19.5/rules_go-v0.19.5.tar.gz",
                "https://github.com/bazelbuild/rules_go/releases/download/0.19.5/rules_go-0.19.5.tar.gz",
            ],
        )
    if "bazel_gazelle" not in excludes:
        http_archive(
            name = "bazel_gazelle",
            sha256 = "7fc87f4170011201b1690326e8c16c5d802836e3a0d617d8f75c3af2b23180c4",
            urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz"],
        )
    if "io_bazel_rules_docker" not in excludes:
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "85a467972ac45e05c6e2bc1ac3af7474a8674acf9f12c8579a89b60b21bb5b33",
            strip_prefix = "rules_docker-369fe43b71b5afcc9e75fabd78eadca017f41343",
            urls = ["https://github.com/bazelbuild/rules_docker/archive/369fe43b71b5afcc9e75fabd78eadca017f41343.tar.gz"],
        )
    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            sha256 = "2ea8a5ed2b448baf4a6855d3ce049c4c452a6470b1efd1504fdb7c1c134d220a",
            strip_prefix = "bazel-skylib-0.8.0",
            urls = ["https://github.com/bazelbuild/bazel-skylib/archive/0.8.0.tar.gz"],
        )
    if "k8s_config" not in excludes:
        # WORKSPACE target to configure the kubectl tool
        kubectl_configure(name = "k8s_config", build_srcs = False)
