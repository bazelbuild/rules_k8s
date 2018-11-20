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
      repository_ctx.download_and_extract(
          "https://github.com/kubernetes/kubernetes/archive/v1.10.10.tar.gz",
          "",
          "4737d3b10b27e391924f89b5ac3aaa5470619b92b75fe1ff5210cc30c56e2e53",
          "tar.gz",
          "kubernetes-1.10.10",)
     # kubectl_tool_path = 
    #else:
    kubectl_tool_path = repository_ctx.which("kubectl")

    repository_ctx.template(
        "BUILD",
        Label("@io_bazel_rules_k8s//toolchains/kubectl:BUILD.tpl"),
        {"%{KUBECTL_TOOL}": "%s" % kubectl_tool_path},
        False,
    )

kubectl_configure = repository_rule(
    implementation = _impl,
    attrs = {"build_kubectl": attr.bool(
        default = False,
        mandatory = False,
    )},
)
