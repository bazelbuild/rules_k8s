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
    substitutions = None
    label = None
    if repository_ctx.attr.build_srcs:
        kubectl_target = "@io_kubernetes//cmd/kubectl:kubectl"
        substitutions = {"%{KUBECTL_TARGET}": "%s" % kubectl_target}
        template = Label("@io_bazel_rules_k8s//toolchains/kubectl:BUILD.target.tpl")
    else:
        kubectl_tool_path = repository_ctx.which("kubectl") or ""
        substitutions = {"%{KUBECTL_TOOL}": "%s" % kubectl_tool_path}
        template = Label("@io_bazel_rules_k8s//toolchains/kubectl:BUILD.path.tpl")

    repository_ctx.template(
        "BUILD",
        template,
        substitutions,
        False,
    )

_kubectl_configure = repository_rule(
    implementation = _impl,
    attrs = {
        "build_srcs": attr.bool(
            doc = "Optional. Set to true to build kubectl from sources.",
            default = False,
            mandatory = False,
        ),
    },
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def kubectl_configure(name, **kwargs):
    """
    Creates an external repository with a kubectl_toolchain target
    properly configured.

    Args:
        **kwargs:
      Required Args
        name: A unique name for this rule.
      Default Args:
        build_srcs: Optional. Set to true to build kubectl from sources. Default: False
        k8s_commit: Otional. Commit / release tag at which to build kubectl
          from. Default "v1.13.0-beta.1"
        k8s_sha256: Otional. sha256 of commit at which to build kubectl from.
          Default <valid sha for default version>.
        k8s_prefix: Otional. Prefix to strip from commit / release archive.
          Typically the same as the commit, or Kubernetes-<release tag>.
          Default <valid prefix for default version>.
      Note: Not all versions/commits of kubernetes project can be used to compile
      kubectl from an external repo. Notably, we have only tested with v1.13.0-beta.1
      or above. Note this rule has a hardcoded pointer to io_kubernetes_build repo
      if your commit (above v1.13.0-beta.1) does not work due to problems,
      related to @io_kubernetes_build repo, please send a PR to update these values.
    """
    build_srcs = False
    if "build_srcs" in kwargs and kwargs["build_srcs"]:
        build_srcs = True

        # We keep these defaults here as they are only used by in this macro and not by the repo rule.
        k8s_commit = kwargs["k8s_commit"] if "k8s_commit" in kwargs else "v1.13.0-beta.1"
        k8s_sha256 = kwargs["k8s_sha256"] if "k8s_sha256" in kwargs else "dfb39ce36284c1ce228954ca12bf016c09be61e40a875e8af4fff84e116bd3a7"
        k8s_prefix = kwargs["k8s_prefix"] if "k8s_prefix" in kwargs else "kubernetes-1.13.0-beta.1"
        http_archive(
            name = "io_kubernetes",
            sha256 = k8s_sha256,
            strip_prefix = k8s_prefix,
            urls = [("https://github.com/kubernetes/kubernetes/archive/%s.tar.gz" % k8s_commit)],
        )
        http_archive(
            name = "io_kubernetes_build",
            sha256 = "21160531ea8a9a4001610223ad815622bf60671d308988c7057168a495a7e2e8",
            strip_prefix = "repo-infra-b4bc4f1552c7fc1d4654753ca9b0e5e13883429f",
            urls = ["https://github.com/kubernetes/repo-infra/archive/b4bc4f1552c7fc1d4654753ca9b0e5e13883429f.tar.gz"],
        )
    _kubectl_configure(name = name, build_srcs = build_srcs)
