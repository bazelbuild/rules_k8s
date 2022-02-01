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
            sha256 = "ba59d7e97eb131d8f8f52d19cb124bb67772f4c7f4d14cb2919deb885ef8c572",
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
            sha256 = "08c3cd71857d58af3cda759112437d9e63339ac9c6e0042add43f4d94caf632d",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.24.2/rules_go-v0.24.2.tar.gz",
                "https://github.com/bazelbuild/rules_go/releases/download/v0.24.2/rules_go-v0.24.2.tar.gz",
            ],
        )
    if "bazel_gazelle" not in excludes:
        http_archive(
            name = "bazel_gazelle",
            sha256 = "d4113967ab451dd4d2d767c3ca5f927fec4b30f3b2c6f8135a2033b9c05a5687",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.0/bazel-gazelle-v0.22.0.tar.gz",
                "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.0/bazel-gazelle-v0.22.0.tar.gz",
            ],
        )
    if "io_bazel_rules_docker" not in excludes:
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "6287241e033d247e9da5ff705dd6ef526bac39ae82f3d17de1b69f8cb313f9cd",
            strip_prefix = "rules_docker-0.14.3",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.3/rules_docker-v0.14.3.tar.gz"],
        )
    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            sha256 = "7ac0fa88c0c4ad6f5b9ffb5e09ef81e235492c873659e6bb99efb89d11246bcb",
            strip_prefix = "bazel-skylib-1.0.3",
            urls = ["https://github.com/bazelbuild/bazel-skylib/archive/1.0.3.tar.gz"],
        )
    if "k8s_config" not in excludes:
        # WORKSPACE target to configure the kubectl tool
        kubectl_configure(name = "k8s_config", build_srcs = False)
