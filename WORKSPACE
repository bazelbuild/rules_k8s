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
    sha256 = "f1748989842b46fa208b2a6e4e2785133cfcc3e4d43c17fecb023733f0f5443f",
    strip_prefix = "protobuf-3.7.1",
    url = "https://github.com/google/protobuf/archive/v3.7.1.tar.gz",
)

# Mention subpar directly to ensure we get version 2.0.0,
# which included fixes for incompatible change flags added in Bazel 0.25. This
# can be removed once other dependencies are updated.
git_repository(
    name = "subpar",
    remote = "https://github.com/google/subpar.git",
    tag = "2.0.0",
)

http_archive(
    name = "base_images_docker",
    sha256 = "d78d3a6851e329bc086af343b3d8bc3eed8d06b02605b504d0cc20da41d07acd",
    strip_prefix = "base-images-docker-8c490f943bbdedde8e68f852fb3bd1d84b26a2f5",
    urls = ["https://github.com/GoogleCloudPlatform/base-images-docker/archive/8c490f943bbdedde8e68f852fb3bd1d84b26a2f5.tar.gz"],
)

http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "2a71e2ddc445c81bd5413fbf8d3b27d2d01daf2d6602a2b6254bc49da8bfa431",
    strip_prefix = "rules_docker-3bea22a4e1454508e8aae45ca70c79f8ed00fc1d",
    urls = ["https://github.com/bazelbuild/rules_docker/archive/3bea22a4e1454508e8aae45ca70c79f8ed00fc1d.tar.gz"],
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

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "a82a352bffae6bee4e95f68a8d80a70e87f42c4741e6a448bec11998fcc82329",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/0.18.5/rules_go-0.18.5.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.18.5/rules_go-0.18.5.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

# ================================================================
# Imports for examples/
# ================================================================

# rules_python is a transitive dep of build_stack_rules_proto, so place it
# first if we're going to explicitly mention it at all

git_repository(
    name = "io_bazel_rules_python",
    commit = "f7a96a4756aeda1cd0ece89f9813fc2c393c20a8",  # 2019-03-07
    remote = "https://github.com/bazelbuild/rules_python.git",
)

load(
    "@io_bazel_rules_python//python:pip.bzl",
    "pip_import",
    "pip_repositories",
)

pip_repositories()

http_archive(
    name = "build_stack_rules_proto",
    sha256 = "22679ab1588d9074dddee3f4f796c020e9be41b7b223e06d48bd68dbde713aee",
    strip_prefix = "rules_proto-bdf16170163f014d92f7bae3a95bb9105b116aef",
    urls = ["https://github.com/stackb/rules_proto/archive/bdf16170163f014d92f7bae3a95bb9105b116aef.tar.gz"],
)

load("@build_stack_rules_proto//:deps.bzl", "io_grpc_grpc_java")

io_grpc_grpc_java()

load("@io_grpc_grpc_java//:repositories.bzl", "grpc_java_repositories")

grpc_java_repositories(omit_com_google_protobuf = True)

load("@build_stack_rules_proto//java:deps.bzl", "java_grpc_library")

java_grpc_library()

load("@build_stack_rules_proto//cpp:deps.bzl", "cpp_grpc_library")

cpp_grpc_library()

http_archive(
    name = "com_github_grpc_grpc",
    patch_args = ["-p1"],
    # TODO(nlopezgi): Remove patch once issue is fixed upstream.
    patches = [
        "//third_party/com_github_grpc_grpc:bcc9f308c6.patch",
    ],
    sha256 = "c0ae4f3f6f946f7e0093eaf68c3fc103f3b720c886f4fcba6589b964b1454a53",
    strip_prefix = "grpc-77eb7306d89892a9c11353fa90e658564df305a6",
    urls = ["https://github.com/grpc/grpc/archive/77eb7306d89892a9c11353fa90e658564df305a6.tar.gz"],
)

load("@com_github_grpc_grpc//bazel:grpc_deps.bzl", "grpc_deps")

grpc_deps()

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
    commit = "45f7cbde4bf88042154385fea3d559d81be4f252",
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
