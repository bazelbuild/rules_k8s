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


def _impl(ctx):
  """Core implementation of kubeval."""
  content="""
#!/bin/bash
set -e

# The schema directory has to have the structure 'kubernetes-json-schema/master', so do that in a tmpdir
tmp_dir=$(mktemp -d)
trap "{{ rm -rf $tmp_dir; }}" EXIT

schema_dir=$tmp_dir/kubernetes-json-schema/master/
mkdir -p $schema_dir
ln -s $(pwd)/external/kubeval_schemas/* $schema_dir

cat {config} | {kubeval} --schema-location=file://$tmp_dir --kubernetes-version={kube_version}
""".format(
    kubeval=ctx.executable._kubeval.short_path,
    config=ctx.file.config.short_path,
    schemas=ctx.attr._schemas,
    kube_version=ctx.attr.kubernetes_version)

  ctx.actions.write(output=ctx.outputs.executable, content=content, is_executable=True)
  return struct(
      runfiles=ctx.runfiles(
          files=[ctx.executable._kubeval,
                 ctx.file.config] + 
                 ctx.attr._schemas.data_runfiles.files.to_list() +
                 ctx.attr._schemas.default_runfiles.files.to_list())
  )


kubeval_test = rule(
    attrs = {
        "config": attr.label(
            allow_files = True,
            doc = "Config file to validate.",
            mandatory = True,
            single_file = True,
        ),
        "kubernetes_version": attr.string(
            default = "master",
            doc = "Version of Kubernetes to validate against."
        ),
        "_kubeval": attr.label(
            default = Label("@kubeval//:kubeval"),
            cfg = "target",
            executable = True,
            allow_files = True,
        ),
        "_schemas": attr.label(
            default = Label("@kubeval_schemas//:schemas"),
            allow_files = True,
            single_file = False,
        )
    },
    executable = True,
    test = True,
    implementation = _impl,
)

