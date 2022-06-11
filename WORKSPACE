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
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//k8s:k8s.bzl", "k8s_defaults", "k8s_repositories")

http_archive(
    name = "com_google_protobuf",
    strip_prefix = "protobuf-3.20.1",
    url = "https://github.com/google/protobuf/archive/v3.20.1.tar.gz",
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

# Tell Gazelle to use @io_bazel_rules_docker as the external repository for rules_docker go packages
# gazelle:repository go_repository name=io_bazel_rules_docker importpath=github.com/bazelbuild/rules_docker

http_archive(
    name = "rules_python",
    sha256 = "cdf6b84084aad8f10bf20b46b77cb48d83c319ebe6458a18e9d2cebf57807cdd",
    strip_prefix = "rules_python-0.8.1",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.8.1.tar.gz",
)

k8s_repositories()

load("@io_bazel_rules_docker//repositories:repositories.bzl", _rules_docker_repos = "repositories")

_rules_docker_repos()

load("//k8s:k8s_go_deps.bzl", k8s_go_deps = "deps")

k8s_go_deps()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

# Mention subpar directly to ensure we get version 2.0.0,
# which included fixes for incompatible change flags added in Bazel 0.25. This
# can be removed once other dependencies are updated.
git_repository(
    name = "subpar",
    commit = "9fae6b63cfeace2e0fb93c9c1ebdc28d3991b16f",
    remote = "https://github.com/google/subpar.git",
)

# Only needed if using the packaging rules.
load("@rules_python//python:pip.bzl", "pip_install")

pip_install(
    name = "py_deps",
    #python_interpreter_target = interpreter,
    requirements = "//:requirements.txt",
)

http_archive(
    name = "com_github_grpc_grpc",
    sha256 = "acf247ec3a52edaee5dee28644a4e485c5e5badf46bdb24a80ca1d76cb8f1174",
    strip_prefix = "grpc-1.37.1",
    urls = ["https://github.com/grpc/grpc/archive/v1.37.1.tar.gz"],
)

load("@com_github_grpc_grpc//bazel:grpc_deps.bzl", "grpc_deps")

grpc_deps()

load("@com_github_grpc_grpc//bazel:grpc_extra_deps.bzl", "grpc_extra_deps")

grpc_extra_deps()

pip_install(
    name = "grpc_python_dependencies",
    requirements = "@com_github_grpc_grpc//:requirements.bazel.txt",
)

# upb_deps and apple_rules_dependencies are needed for grpc
load("@upb//bazel:workspace_deps.bzl", "upb_deps")

upb_deps()

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

# https://rules-proto-grpc.com/en/latest/#installation
http_archive(
    name = "rules_proto_grpc",
    sha256 = "507e38c8d95c7efa4f3b1c0595a8e8f139c885cb41a76cab7e20e4e67ae87731",
    strip_prefix = "rules_proto_grpc-4.1.1",
    urls = ["https://github.com/rules-proto-grpc/rules_proto_grpc/archive/4.1.1.tar.gz"],
)

load("@rules_proto_grpc//:repositories.bzl", "rules_proto_grpc_repos", "rules_proto_grpc_toolchains")

rules_proto_grpc_toolchains()

rules_proto_grpc_repos()

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")

rules_proto_dependencies()

rules_proto_toolchains()

load("@rules_proto_grpc//go:repositories.bzl", rules_proto_grpc_go_repos = "go_repos")

rules_proto_grpc_go_repos()

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

gazelle_dependencies()

# We use go_image to build a sample service
load(
    "@io_bazel_rules_docker//go:image.bzl",
    _go_image_repos = "repositories",
)

_go_image_repos()

# gazelle:repo bazel_gazelle

# Go dependencies needed for rules_k8s tests only.
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
