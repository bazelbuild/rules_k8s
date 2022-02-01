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
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//toolchains/kubectl:kubectl_configure.bzl", "kubectl_configure")
load(":with-defaults.bzl", _k8s_defaults = "k8s_defaults")

k8s_defaults = _k8s_defaults

_com_github_yaml_pyyaml_build_file = """\
load("@rules_python//python:defs.bzl", "py_binary", "py_library")

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
"""

# buildifier: disable=unnamed-macro
def k8s_repositories():
    """Download dependencies of k8s rules."""

    # Used by utilities for roundtripping yaml.
    maybe(
        http_archive,
        name = "com_github_yaml_pyyaml",
        build_file_content = _com_github_yaml_pyyaml_build_file,
        sha256 = "e9df8412ddabc9c21b4437ee138875b95ebb32c25f07f962439e16005152e00e",
        strip_prefix = "pyyaml-5.1.2",
        urls = ["https://github.com/yaml/pyyaml/archive/5.1.2.zip"],
    )

    # Register the default kubectl toolchain targets for supported platforms
    # note these work with the autoconfigured toolchain
    native.register_toolchains(
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_amd64_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_arm64_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_s390x_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_amd64_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_arm64_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_windows_toolchain",
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_go",
        sha256 = "52d0a57ea12139d727883c2fef03597970b89f2cc2a05722c42d1d7d41ec065b",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.24.13/rules_go-v0.24.13.tar.gz",
            "https://github.com/bazelbuild/rules_go/releases/download/v0.24.13/rules_go-v0.24.13.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "bazel_gazelle",
        sha256 = "222e49f034ca7a1d1231422cdb67066b885819885c356673cb1f72f748a3c9d4",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.3/bazel-gazelle-v0.22.3.tar.gz",
            "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.3/bazel-gazelle-v0.22.3.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_docker",
        sha256 = "92779d3445e7bdc79b961030b996cb0c91820ade7ffa7edca69273f404b085d5",
        strip_prefix = "rules_docker-0.20.0",
        urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.20.0/rules_docker-v0.20.0.tar.gz"],
    )

    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "7ac0fa88c0c4ad6f5b9ffb5e09ef81e235492c873659e6bb99efb89d11246bcb",
        strip_prefix = "bazel-skylib-1.0.3",
        urls = ["https://github.com/bazelbuild/bazel-skylib/archive/1.0.3.tar.gz"],
    )

    # WORKSPACE target to configure the kubectl tool
    maybe(
        kubectl_configure,
        name = "k8s_config",
        build_srcs = False,
    )
