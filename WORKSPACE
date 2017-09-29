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
workspace(name = "io_bazel_rules_k8s")

git_repository(
    name = "io_bazel_rules_docker",
    commit = "839a297d4e874216b4fd93f09dd35be5592dc10e",
    remote = "https://github.com/bazelbuild/rules_docker.git",
)

load(
    "@io_bazel_rules_docker//docker:docker.bzl",
    "docker_repositories",
)

docker_repositories()

load("//k8s:k8s.bzl", "k8s_repositories", "k8s_defaults")

k8s_repositories()

k8s_defaults(
    name = "k8s_deploy",
    cluster = "gke_rules-k8s_us-central1-f_testing",
    image_chroot = "us.gcr.io/rules_k8s/{BUILD_USER}",
    kind = "deployment",
    namespace = "{BUILD_USER}",
)

k8s_defaults(
    name = "k8s_service",
    cluster = "gke_rules-k8s_us-central1-f_testing",
    kind = "service",
    namespace = "{BUILD_USER}",
)

new_http_archive(
    name = "mock",
    build_file_content = """
# Rename mock.py to __init__.py
genrule(
    name = "rename",
    srcs = ["mock.py"],
    outs = ["__init__.py"],
    cmd = "cat $< >$@",
)
py_library(
   name = "mock",
   srcs = [":__init__.py"],
   visibility = ["//visibility:public"],
)""",
    sha256 = "b839dd2d9c117c701430c149956918a423a9863b48b09c90e30a6013e7d2f44f",
    strip_prefix = "mock-1.0.1/",
    type = "tar.gz",
    url = "https://pypi.python.org/packages/source/m/mock/mock-1.0.1.tar.gz",
)

# ================================================================
# Imports for examples/
# ================================================================

git_repository(
    name = "org_pubref_rules_protobuf",
    commit = "d9523f3d443b6a4f3fabc72051d84eb5474d7745",  # v0.8.1 (Sep 23 2017)
    remote = "https://github.com/pubref/rules_protobuf.git",
)

load("@org_pubref_rules_protobuf//protobuf:rules.bzl", "proto_repositories")

proto_repositories()

load("@org_pubref_rules_protobuf//cpp:rules.bzl", "cpp_proto_repositories")

cpp_proto_repositories()

load("@org_pubref_rules_protobuf//java:rules.bzl", "java_proto_repositories")

java_proto_repositories()

# We use cc_image to build a sample service
load(
    "@io_bazel_rules_docker//cc:image.bzl",
    _cc_image_repos = "repositories",
)

_cc_image_repos()

# We use java_image to build a sample service
load(
    "@io_bazel_rules_docker//java:image.bzl",
    _java_image_repos = "repositories",
)

_java_image_repos()

git_repository(
    name = "io_bazel_rules_go",
    commit = "ae70411645c171b2056d38a6a959e491949f9afe",
    remote = "https://github.com/bazelbuild/rules_go.git",
)

load(
    "@io_bazel_rules_go//go:def.bzl",
    "go_repositories",
)

go_repositories()

# We use go_image to build a sample service
load(
    "@io_bazel_rules_docker//go:image.bzl",
    _go_image_repos = "repositories",
)

_go_image_repos()

load("@org_pubref_rules_protobuf//go:rules.bzl", "go_proto_repositories")

go_proto_repositories()

git_repository(
    name = "io_bazel_rules_python",
    commit = "d6fbb0fb2a5c8e318dd4de5104dc41358cefaa90",
    remote = "https://github.com/bazelbuild/rules_python.git",
)

load(
    "@io_bazel_rules_python//python:pip.bzl",
    "pip_import",
    "pip_repositories",
)

pip_repositories()

pip_import(
    name = "examples_helloworld_pip",
    requirements = "//examples/hellogrpc/py:requirements.txt",
)

load("@examples_helloworld_pip//:requirements.bzl", "pip_install")

pip_install()

# We use py_image to build a sample service
load(
    "@io_bazel_rules_docker//python:image.bzl",
    _py_image_repos = "repositories",
)

_py_image_repos()

load("@org_pubref_rules_protobuf//python:rules.bzl", "py_proto_repositories")

py_proto_repositories()

git_repository(
    name = "io_bazel_rules_jsonnet",
    commit = "09ec18db5b9ad3129810f5f0ccc86363a8bfb6be",
    remote = "https://github.com/bazelbuild/rules_jsonnet.git",
)

load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_repositories")

jsonnet_repositories()
