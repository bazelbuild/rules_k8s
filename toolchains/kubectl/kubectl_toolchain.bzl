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
This module implements the kubectl toolchain rule.
"""

KubectlInfo = provider(
    doc = "Information about how to invoke the kubectl tool.",
    fields = {
        "tool_path": "Path to the kubectl executable",
        "tool_target": "Target to build kubectl executable",
    },
)

def _kubectl_toolchain_impl(ctx):
    if not ctx.attr.tool_path and not ctx.attr.tool_target:
        print("No kubectl tool was found or built, executing run for rules_k8s targets might not work.")
    toolchain_info = platform_common.ToolchainInfo(
        kubectlinfo = KubectlInfo(
            tool_path = ctx.attr.tool_path,
            tool_target = ctx.attr.tool_target,
        ),
    )
    return [toolchain_info]

kubectl_toolchain = rule(
    implementation = _kubectl_toolchain_impl,
    attrs = {
        "tool_path": attr.string(
            doc = "Absolute path to a pre-installed kubectl binary.",
            mandatory = False,
        ),
        "tool_target": attr.label(
            doc = "Target to build kubectl from source.",
            mandatory = False,
        ),
    },
)
