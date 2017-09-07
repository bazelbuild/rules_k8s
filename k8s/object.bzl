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
"""An implementation of k8s_object for interacting with an object of kind."""

def _impl(ctx):
  """Core implementation of k8s_object."""

  # Use expand_template with no substitutions as a glorified copy.
  ctx.actions.expand_template(
      template = ctx.file.template,
      output = ctx.outputs.yaml,
      substitutions = {},
  )

  ctx.action(
      command = """cat > {resolve_script} <<"EOF"
#!/bin/bash -e
{resolver} --template {yaml}
EOF""".format(
        resolver = ctx.executable._resolver.short_path,
        yaml = ctx.outputs.yaml.short_path,
        resolve_script = ctx.outputs.executable.path,
      ),
      inputs = [],
      outputs = [ctx.outputs.executable],
      mnemonic = "ResolveScript"
  )


  return struct(runfiles = ctx.runfiles(files = [
    ctx.executable._resolver,
    ctx.outputs.yaml,
  ]))

_common_attrs = {
    # TODO(mattmoor): Add cluster / namespace once we have executable friends.
    "kind": attr.string(mandatory = True),
    "_resolver": attr.label(
        default = Label("//k8s:resolver.par"),
        cfg = "host",
        executable = True,
        allow_files = True,
    ),
}

_k8s_object = rule(
    attrs = {
        "template": attr.label(
            allow_files = [
                ".yaml",
                ".json",
            ],
            single_file = True,
            mandatory = True,
        ),
        # TODO(mattmoor): images
    } + _common_attrs,
    executable = True,
    outputs = {
        "yaml": "%{name}.yaml",
    },
    implementation = _impl,
)

def k8s_object(name, **kwargs):
  """Interact with a K8s object.
  Args:
    name: name of the rule.
    cluster: the name of the cluster.
    namespace: the namespace within the cluster.
    kind: the object kind.
    template: the yaml template to instantiate.
  """

  _k8s_object(name=name, **kwargs)
