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
load("//k8s:k8s.bzl", "k8s_defaults", "k8s_repositories")

k8s_repositories()

load("@io_bazel_rules_docker//repositories:repositories.bzl", _rules_docker_repos = "repositories")

_rules_docker_repos()

load("//k8s:k8s_go_deps.bzl", k8s_go_deps = "deps")

k8s_go_deps()

http_archive(
    name = "com_google_protobuf",
    sha256 = "512e5a674bf31f8b7928a64d8adf73ee67b8fe88339ad29adaa3b84dbaa570d8",
    strip_prefix = "protobuf-3.12.4",
    url = "https://github.com/google/protobuf/archive/v3.12.4.tar.gz",
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
    name = "rules_python",
    sha256 = "b5668cde8bb6e3515057ef465a35ad712214962f0b3a314e551204266c7be90c",
    strip_prefix = "rules_python-0.0.2",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.0.2/rules_python-0.0.2.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

# Only needed if using the packaging rules.
load("@rules_python//python:pip.bzl", "pip3_import", "pip_repositories")

pip_repositories()

pip3_import(
    name = "py_deps",
    requirements = "//:requirements.txt",
)

load("@py_deps//:requirements.bzl", "pip_install")

pip_install()

http_archive(
    name = "com_github_grpc_grpc",
    sha256 = "ba74b97a2f1b4e22ec5fb69d639d849d2069fb58ea7d6579a31f800af6fe3b6c",
    strip_prefix = "grpc-1.30.2",
    urls = ["https://github.com/grpc/grpc/archive/v1.30.2.tar.gz"],
)

load("@com_github_grpc_grpc//bazel:grpc_deps.bzl", "grpc_deps")

grpc_deps()

load("@com_github_grpc_grpc//bazel:grpc_extra_deps.bzl", "grpc_extra_deps")

grpc_extra_deps()

pip3_import(
    name = "grpc_python_dependencies",
    requirements = "@com_github_grpc_grpc//:requirements.bazel.txt",
)

load("@grpc_python_dependencies//:requirements.bzl", _grpc_pip_install = "pip_install")

_grpc_pip_install()

# upb_deps and apple_rules_dependencies are needed for grpc
load("@upb//bazel:workspace_deps.bzl", "upb_deps")

upb_deps()

load("@build_bazel_rules_apple//apple:repositories.bzl", "apple_rules_dependencies")

apple_rules_dependencies()

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
)

container_pull(
    name = "bazel_image",
    registry = "launcher.gcr.io",
    repository = "google/bazel",
)

container_pull(
    name = "py3_image_base",
    digest = "sha256:025b77e95e701917434c478e7fd267f3d894db5ca74e5b2362fe37ebe63bbeb0",
    registry = "gcr.io",
    repository = "distroless/python3-debian10",
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

_CLUSTER = "gke_rules-k8s_us-central1-f_testing"

_CONTEXT = _CLUSTER

_NAMESPACE = "{STABLE_E2E_NAMESPACE}"

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

# ================================================================
# Imports for examples/
# ================================================================

# rules_python is a transitive dep of build_stack_rules_proto, so place it
# first if we're going to explicitly mention it at all

http_archive(
    name = "build_stack_rules_proto",
    patch_args = ["-p1"],
    patches = [
        "//third_party/build_stack_rules_proto:stackb.patch",
    ],
    sha256 = "2c62ecc133ee0400d969750a5591909a9b3839af402f9c9d148cffb0ce9b374b",
    strip_prefix = "rules_proto-6b334ece48828fb8e45052976d3516f808819ac7",
    urls = ["https://github.com/stackb/rules_proto/archive/6b334ece48828fb8e45052976d3516f808819ac7.tar.gz"],
)

load("@build_stack_rules_proto//:deps.bzl", "io_grpc_grpc_java")

io_grpc_grpc_java()

load("@io_grpc_grpc_java//:repositories.bzl", "grpc_java_repositories")

grpc_java_repositories()

load("@build_stack_rules_proto//java:deps.bzl", "java_grpc_library")

java_grpc_library()

load("@build_stack_rules_proto//go:deps.bzl", "go_grpc_library")

go_grpc_library()

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

git_repository(
    name = "io_bazel_rules_jsonnet",
    commit = "12979862ab51358a8a5753f5a4aa0658fec9d4af",
    remote = "https://github.com/bazelbuild/rules_jsonnet.git",
    shallow_since = "1574670556 +0100",
)

load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_repositories")

jsonnet_repositories()

http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "6a67a8a1bf6fddc9113f73471029b819eef4575c3a936a4a01d57e411894d692",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/2.0.2/rules_nodejs-2.0.2.tar.gz"],
)

load("@build_bazel_rules_nodejs//:index.bzl", "yarn_install")

# We use nodejs_image to build a sample service
load(
    "@io_bazel_rules_docker//nodejs:image.bzl",
    _nodejs_image_repos = "repositories",
)

_nodejs_image_repos()

yarn_install(
    name = "examples_hellohttp_npm",
    package_json = "//examples/hellohttp/nodejs:package.json",
    symlink_node_modules = False,
    yarn_lock = "//examples:yarn.lock",
)

http_archive(
    name = "rules_jvm_external",
    sha256 = "e5b97a31a3e8feed91636f42e19b11c49487b85e5de2f387c999ea14d77c7f45",
    strip_prefix = "rules_jvm_external-2.9",
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/2.9.zip",
)

load("@rules_jvm_external//:defs.bzl", "maven_install")

maven_install(
    name = "maven",
    artifacts = [
        "com.google.errorprone:error_prone_annotations:2.3.2",
    ],
    repositories = [
        "https://jcenter.bintray.com",
        "https://repo1.maven.org/maven2",
    ],
)

# error_prone_annotations required by protobuf 3.7.1
bind(
    name = "error_prone_annotations",
    actual = "@maven//:com_google_errorprone_error_prone_annotations",
)

# gazelle:repo bazel_gazelle

# Go dependencies needed for rules_k8s tests only.
load("@bazel_gazelle//:deps.bzl", "go_repository")

go_repository(
    name = "org_golang_google_grpc",
    importpath = "google.golang.org/grpc",
    sum = "h1:C1QC6KzgSiLyBabDi87BbjaGreoRgGUF5nOyvfrAZ1k=",
    version = "v1.28.1",
)

go_repository(
    name = "org_golang_x_net",
    importpath = "golang.org/x/net",
    sum = "h1:h5tBRKZ1aY/bo6GNqe/4zWC8GkaLOFQ5wPKIOQ0i2sA=",
    version = "v0.0.0-20190918130420-a8b05e9114ab",
)

go_repository(
    name = "org_golang_x_text",
    importpath = "golang.org/x/text",
    sum = "h1:tW2bmiBqwgJj/UpqtC8EpXEZVYOwU0yG4iWbprSVAcs=",
    version = "v0.3.2",
)

go_repository(
    name = "org_golang_x_sys",
    importpath = "golang.org/x/sys",
    sum = "h1:uYVVQ9WP/Ds2ROhcaGPeIdVq0RIXVLwsHlnvJ+cT1So=",
    version = "v0.0.0-20200302150141-5c8b2ff67527",
)
