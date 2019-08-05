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

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

http_archive(
    name = "com_google_protobuf",
    sha256 = "2ee9dcec820352671eb83e081295ba43f7a4157181dad549024d7070d079cf65",
    strip_prefix = "protobuf-3.9.0",
    url = "https://github.com/google/protobuf/archive/v3.9.0.tar.gz",
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

# Mention subpar directly to ensure we get version 2.0.0,
# which included fixes for incompatible change flags added in Bazel 0.25. This
# can be removed once other dependencies are updated.
git_repository(
    name = "subpar",
    remote = "https://github.com/google/subpar.git",
    tag = "2.0.0",
)

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "f04d2373bcaf8aa09bccb08a98a57e721306c8f6043a2a0ee610fd6853dcde3d",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/0.18.6/rules_go-0.18.6.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.18.6/rules_go-0.18.6.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "com_github_grpc_grpc",
    sha256 = "ad83a8d8446b817a41d974ed2489ee77d3de83d4c27eeafe6299bc0906cd63dc",
    strip_prefix = "grpc-d3316ad22e9122a2022ffe41f819dd670db05c49",
    # Commit from 2019-05-30
    urls = ["https://github.com/grpc/grpc/archive/d3316ad22e9122a2022ffe41f819dd670db05c49.tar.gz"],
)

load("@com_github_grpc_grpc//bazel:grpc_deps.bzl", "grpc_deps")

grpc_deps()

http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "6706b3979498802672252e77a45674dae0a1036f246a7efe5d3adbe53dcbea31",
    strip_prefix = "rules_docker-31c38b0f506d8aff07487c274ed045c0017f689f",
    urls = ["https://github.com/bazelbuild/rules_docker/archive/31c38b0f506d8aff07487c274ed045c0017f689f.tar.gz"],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
)

container_pull(
    name = "bazel_image",
    registry = "launcher.gcr.io",
    repository = "google/bazel",
)

# Gcloud installer
http_file(
    name = "gcloud_archive",
    downloaded_file_path = "google-cloud-sdk.tar.gz",
    sha256 = "a2205e35b11136004d52d47774762fbec9145bf0bda74ca506f52b71452c570e",
    urls = [
        "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-220.0.0-linux-x86_64.tar.gz",
    ],
)

load("//k8s:k8s.bzl", "k8s_defaults", "k8s_repositories")

k8s_repositories()

_CLUSTER = "gke_rules-k8s_us-central1-f_testing"

_CONTEXT = _CLUSTER

_NAMESPACE = "{E2E_NAMESPACE}"

k8s_defaults(
    name = "k8s_object",
    cluster = _CLUSTER,
    context = _CONTEXT,
    image_chroot = "us.gcr.io/rules_k8s/{BUILD_USER}",
    namespace = _NAMESPACE,
)

k8s_defaults(
    name = "k8s_deploy",
    cluster = _CLUSTER,
    context = _CONTEXT,
    image_chroot = "us.gcr.io/rules_k8s/{BUILD_USER}",
    kind = "deployment",
    namespace = _NAMESPACE,
)

[k8s_defaults(
    name = "k8s_" + kind,
    cluster = _CLUSTER,
    context = _CONTEXT,
    kind = kind,
    namespace = _NAMESPACE,
) for kind in [
    "service",
    "crd",
    "todo",
]]

http_archive(
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

# rules_python is a transitive dep of build_stack_rules_proto, so place it
# first if we're going to explicitly mention it at all

git_repository(
    name = "rules_python",
    commit = "4b84ad270387a7c439ebdccfd530e2339601ef27",  # 2019-03-07
    remote = "https://github.com/bazelbuild/rules_python.git",
)

load(
    "@rules_python//python:pip.bzl",
    "pip_import",
    "pip_repositories",
)

pip_repositories()

http_archive(
    name = "build_stack_rules_proto",
    sha256 = "85ccc69a964a9fe3859b1190a7c8246af2a4ead037ee82247378464276d4262a",
    strip_prefix = "rules_proto-d9a123032f8436dbc34069cfc3207f2810a494ee",
    urls = ["https://github.com/stackb/rules_proto/archive/d9a123032f8436dbc34069cfc3207f2810a494ee.tar.gz"],
)

load("@build_stack_rules_proto//:deps.bzl", "io_grpc_grpc_java")

io_grpc_grpc_java()

load("@io_grpc_grpc_java//:repositories.bzl", "grpc_java_repositories")

grpc_java_repositories(omit_com_google_protobuf = True)

load("@build_stack_rules_proto//java:deps.bzl", "java_grpc_library")

java_grpc_library()

load("@build_stack_rules_proto//cpp:deps.bzl", "cpp_grpc_library")

cpp_grpc_library()

load("@build_stack_rules_proto//go:deps.bzl", "go_grpc_library")

go_grpc_library()

load("@build_stack_rules_proto//python:deps.bzl", "python_grpc_library")

python_grpc_library()

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

# We use go_image to build a sample service
load(
    "@io_bazel_rules_docker//go:image.bzl",
    _go_image_repos = "repositories",
)

_go_image_repos()

pip_import(
    name = "protobuf_py_deps",
    requirements = "@build_stack_rules_proto//python/requirements:protobuf.txt",
)

load("@protobuf_py_deps//:requirements.bzl", protobuf_pip_install = "pip_install")

protobuf_pip_install()

pip_import(
    name = "grpc_py_deps",
    requirements = "@build_stack_rules_proto//python:requirements.txt",
)

load("@grpc_py_deps//:requirements.bzl", grpc_pip_install = "pip_install")

grpc_pip_install()

pip_import(
    name = "examples_helloworld_pip",
    requirements = "//examples/hellogrpc/py:requirements.txt",
)

load(
    "@examples_helloworld_pip//:requirements.bzl",
    setuptools_pip_install = "pip_install",
)

setuptools_pip_install()

pip_import(
    name = "examples_hellohttp_pip",
    requirements = "//examples/hellohttp/py:requirements.txt",
)

load(
    "@examples_hellohttp_pip//:requirements.bzl",
    httppip_install = "pip_install",
)

httppip_install()

# We use py_image to build a sample service
load(
    "@io_bazel_rules_docker//python:image.bzl",
    _py_image_repos = "repositories",
)

_py_image_repos()

git_repository(
    name = "io_bazel_rules_jsonnet",
    commit = "a7983a439bd555033e26f7f3da3cbeca25a44408",
    remote = "https://github.com/bazelbuild/rules_jsonnet.git",
)

load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_repositories")

jsonnet_repositories()

pip_import(
    name = "examples_todocontroller_pip",
    requirements = "//examples/todocontroller/py:requirements.txt",
)

load(
    "@examples_todocontroller_pip//:requirements.bzl",
    _controller_pip_install = "pip_install",
)

_controller_pip_install()

http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "b996a3ce55c49ae359468dae040b30025fdc0917f67b08c36929ecb1ea02907e",
    strip_prefix = "rules_nodejs-0.16.3",
    urls = ["https://github.com/bazelbuild/rules_nodejs/archive/0.16.3.zip"],
)

load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories", "npm_install")

node_repositories(package_json = ["//examples/hellohttp/nodejs:package.json"])

# We use nodejs_image to build a sample service
load(
    "@io_bazel_rules_docker//nodejs:image.bzl",
    _nodejs_image_repos = "repositories",
)

_nodejs_image_repos()

npm_install(
    name = "examples_hellohttp_npm",
    package_json = "//examples/hellohttp/nodejs:package.json",
)

# error_prone_annotations required by protobuf 3.7.1
maven_jar(
    name = "error_prone_annotations_maven",
    artifact = "com.google.errorprone:error_prone_annotations:2.3.2",
)

bind(
    name = "error_prone_annotations",
    actual = "@error_prone_annotations_maven//jar",
)
