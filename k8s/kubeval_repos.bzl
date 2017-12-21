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
"""Repository rules for kubeval, for validating k8s objects."""

_KUBEVAL_VERSION = "0.6.0/"

_KUBEVAL_BASE_URL = "https://github.com/garethr/kubeval/releases/download/"

_KUBEVAL_URLS = {
    "darwin": _KUBEVAL_BASE_URL + _KUBEVAL_VERSION + "kubeval-darwin-amd64.tar.gz",
    "linux": _KUBEVAL_BASE_URL + _KUBEVAL_VERSION + "kubeval-linux-amd64.tar.gz",
}

_KUBEVAL_SHAS = {
    "darwin": "40122cce2abe1b51ea9752ff00fee61ae3107623d66d7ffc776c8edae8fa9b91",
    "linux": "b6912927c0df8e4bb7e3a842668de6302b1e81aac476e5cec11772c7e6d98254",
}

def _kubeval_repositories_impl(repository_ctx):
    if repository_ctx.os.name == 'mac os x':
        platform = 'darwin'
    else:
        platform = 'linux'
    
    repository_ctx.download_and_extract(
        url=_KUBEVAL_URLS[platform],
        output=repository_ctx.path("bin"),
        type='.tar.gz',
        sha256=_KUBEVAL_SHAS[platform]
    )

    kubeval_script_contents = """#!/bin/bash
set -e
find .
kubeval --kubernetes-version={kube_version} --schema-location=$1
""".format(kube_version=repository_ctx.attr.kube_version)

    repository_ctx.file(
        "kubeval.sh",
        content=kubeval_script_contents,
        executable=True)


    build = """
package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "kubeval",
    srcs = [":kubeval.sh"],
    data = ["@kubeval_schemas//:schemas", ":bin/kubeval"],
)
""".format(kube_version=repository_ctx.attr.kube_version)

    repository_ctx.file("BUILD", build)

_kubeval_repositories = repository_rule(
    attrs = {
        "kube_version": attr.string(mandatory = True),
    },
    implementation = _kubeval_repositories_impl,
)

def kubeval_repositories(kube_version):
    # Master is special cased in the binary.
    if kube_version == "master":
        path = "master"
    else:
        path = "v%s-standalone" % kube_version

    build_file_template = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name="schemas",
    srcs=glob(["{kube_version}/**/*"]),
)
"""
    build_file_content = build_file_template.format(kube_version=path)
    native.new_git_repository(
        name="kubeval_schemas",
        commit="27cc8de3a29de73bbe6ddf63006ee4ce1dbf3792",
        remote="https://github.com/garethr/kubernetes-json-schema.git",
        build_file_content=build_file_content
    )
    _kubeval_repositories(name="kubeval", kube_version=kube_version)
