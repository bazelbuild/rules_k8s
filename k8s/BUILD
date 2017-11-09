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
package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

exports_files([
    "apply.sh.tpl",
    "create.sh.tpl",
    "replace.sh.tpl",
    "resolve.sh.tpl",
    "resolve-all.sh.tpl",
    "delete.sh.tpl",
    "describe.sh.tpl",
])

load("@subpar//:subpar.bzl", "par_binary")

py_library(
    name = "resolver_lib",
    srcs = ["resolver.py"],
    deps = [
        "@containerregistry//:containerregistry",
        "@yaml//:yaml",
        "@simplejson//:simplejson",
    ],
)

py_test(
    name = "resolver_test",
    srcs = ["resolver_test.py"],
    data = [
        "//examples/hellogrpc/cc/server:server.tar",
    ],
    deps = [
        ":resolver_lib",
        "@mock//:mock",
    ],
)

par_binary(
    name = "resolver",
    srcs = ["resolver.py"],
    main = "resolver.py",
    visibility = ["//visibility:public"],
    deps = [
        "@containerregistry//:containerregistry",
        "@yaml//:yaml",
        "@simplejson//:simplejson",
    ],
)

par_binary(
    name = "stamper",
    srcs = ["stamper.py"],
    main = "stamper.py",
    visibility = ["//visibility:public"],
)

par_binary(
    name = "pre_processor",
    srcs = ["pre_processor.py"],
    main = "pre_processor.py",
    visibility = ["//visibility:public"],
    deps = [
        "@yaml//:yaml",
        "@simplejson//:simplejson",
    ],
)
