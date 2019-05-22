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

    # Used by utilities for roundtripping yaml.
    http_archive(
        name = "yaml",
        build_file_content = """
py_library(
    name = "yaml",
    srcs = glob(["*.py"]),
    visibility = ["//visibility:public"],
)""",
        sha256 = "592766c6303207a20efc445587778322d7f73b161bd994f227adaa341ba212ab",
        urls = [("https://pypi.python.org/packages/4a/85/" +
                 "db5a2df477072b2902b0eb892feb37d88ac635d36245a72a6a69b23b383a" +
                 "/PyYAML-3.12.tar.gz")],
        strip_prefix = "PyYAML-3.12/lib/yaml",
    )

    # Register the default kubectl toolchain targets for supported platforms
    # note these work with the autoconfigured toolchain
    native.register_toolchains(
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_toolchain",
        "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_windows_toolchain",
    )

    excludes = native.existing_rules().keys()
    if "io_bazel_rules_go" not in excludes:
        # Only needed when building kubectl from source. It's always included
        # here to keep all the http_archive calls in one function for simplicity.
        http_archive(
            name = "io_bazel_rules_go",
            sha256 = "a82a352bffae6bee4e95f68a8d80a70e87f42c4741e6a448bec11998fcc82329",
            url = "https://github.com/bazelbuild/rules_go/releases/download/0.18.5/rules_go-0.18.5.tar.gz",
        )
    if "k8s_config" not in excludes:
        # WORKSPACE target to configure the kubectl tool
        kubectl_configure(name = "k8s_config", build_srcs = False)
