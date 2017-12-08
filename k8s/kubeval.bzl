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
"""An implementation of kubeval for validating k8s objects."""

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
        output=repository_ctx.path(""),
        type='.tar.gz',
        sha256=_KUBEVAL_SHAS[platform]
    )
    build = """
package(default_visibility = ["//visibility:public"])
exports_files(["kubeval"])
"""
    repository_ctx.file("BUILD", build)

_kubeval_repositories = repository_rule(implementation = _kubeval_repositories_impl)

def _impl(ctx):
  """Core implementation of kubeval."""
  content="""
#!/bin/bash
set -e
cat {config} | {kubeval}
""".format(
    kubeval=ctx.executable._kubeval.short_path,
    config=ctx.file.config.short_path)

  ctx.actions.write(output=ctx.outputs.executable, content=content, is_executable=True)
  return struct(
      runfiles=ctx.runfiles(files=[ctx.executable._kubeval, ctx.file.config])
  )


# TODO(dlorenc): expose more paramters for things like API version and custom schema location
kubeval_test = rule(
    attrs = {
        "config": attr.label(
            allow_files = True,
            doc = "Config file to validate.",
            mandatory = True,
            single_file = True,
        ),
        "_kubeval": attr.label(
            default = Label("@kubeval//:kubeval"),
            cfg = "target",
            executable = True,
            allow_files = True,
        ),
    },
    executable = True,
    test = True,
    implementation = _impl,
)

def kubeval_repositories():
    _kubeval_repositories(name="kubeval")
