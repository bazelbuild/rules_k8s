# Copyright 2018 The Bazel Authors. All rights reserved.
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
"""
Defines a repository rule for configuring the kubectl tool.
"""

def _impl(repository_ctx):
    kubectl_tool_path = None
    if repository_ctx.attr.build_kubectl:
      kubectl_tool_path = "@io_kubernetes//cmd/kubectl:kubectl"
    else:
      kubectl_tool_path = repository_ctx.which("kubectl")

    repository_ctx.template(
        "BUILD",
        Label("@io_bazel_rules_k8s//toolchains/kubectl:BUILD.tpl"),
        {"%{KUBECTL_TOOL}": "%s" % kubectl_tool_path},
        False,
    )

_kubectl_configure = repository_rule(
    implementation = _impl,
    attrs = {"build_kubectl": attr.bool(
        default = False,
        mandatory = False,
    )},
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def kubectl_build(name, **kwargs):
  http_archive(
      name = "io_kubernetes",
      sha256 = "4737d3b10b27e391924f89b5ac3aaa5470619b92b75fe1ff5210cc30c56e2e53",
      strip_prefix = "kubernetes-1.10.10",
      urls = ["https://github.com/kubernetes/kubernetes/archive/v1.10.10.tar.gz"],
  )
  http_archive(
      name = "io_kubernetes_build",
      sha256 = "21160531ea8a9a4001610223ad815622bf60671d308988c7057168a495a7e2e8",
      strip_prefix = "repo-infra-b4bc4f1552c7fc1d4654753ca9b0e5e13883429f",
      urls = ["https://github.com/kubernetes/repo-infra/archive/b4bc4f1552c7fc1d4654753ca9b0e5e13883429f.tar.gz"],
  )
  _kubectl_configure(name = name, build_kubectl=True, **kwargs)

def kubectl_configure(name, **kwargs):
  _kubectl_configure(name = name, **kwargs)
