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

load("@subpar//:subpar.bzl", "par_binary")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

exports_files([
    "apply.sh.tpl",
    "create.sh.tpl",
    "replace.sh.tpl",
    "resolve.sh.tpl",
    "resolve-all.sh.tpl",
    "reverse.sh.tpl",
    "delete.sh.tpl",
    "describe.sh.tpl",
    "diff.sh.tpl",
])

py_library(
    name = "resolver_lib",
    srcs = [
        "__init__.py",
        "resolver.py",
        "//:__init__.py",
    ],
    deps = [
        "@com_github_yaml_pyyaml//:yaml",
        "@containerregistry",
    ],
)

py_test(
    name = "resolver_test",
    srcs = ["resolver_test.py"],
    data = [
        "//examples/hellogrpc/cc/server:server.tar",
    ],
    python_version = "PY2",
    deps = [
        ":resolver_lib",
        "@mock",
    ],
)

par_binary(
    name = "resolver",
    srcs = ["resolver.py"],
    main = "resolver.py",
    python_version = "PY2",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_yaml_pyyaml//:yaml",
        "@containerregistry",
    ],
)

par_binary(
    name = "stamper",
    srcs = ["stamper.py"],
    main = "stamper.py",
    python_version = "PY2",
    visibility = ["//visibility:public"],
)

par_binary(
    name = "reverser",
    srcs = ["reverser.py"],
    main = "reverser.py",
    python_version = "PY2",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_yaml_pyyaml//:yaml",
    ],
)
