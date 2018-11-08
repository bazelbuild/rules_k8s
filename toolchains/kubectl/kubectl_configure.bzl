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

    kubectl_tool_path = repository_ctx.which("kubectl")

    repository_ctx.template(
        "BUILD",
        Label("//toolchains/kubectl:BUILD.tpl"),
        {"%{KUBECTL_TOOL}": "%s" % kubectl_tool_path},
        False
    )

kubectl_configure = repository_rule(
    implementation = _impl,
)

# Specifying a string or path will be relative to the local_k8s_config repo.
# Using Label requires using an absolute path.