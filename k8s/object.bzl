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

load(
    "@io_bazel_rules_docker//docker:layers.bzl",
    _get_layers = "get_from_target",
    _layer_tools = "tools",
)
load(
    "@io_bazel_rules_docker//docker:label.bzl",
    _string_to_label = "string_to_label",
)

def _impl(ctx):
  """Core implementation of k8s_object."""

  # Use expand_template with no substitutions as a glorified copy.
  ctx.actions.expand_template(
      template = ctx.file.template,
      output = ctx.outputs.yaml,
      substitutions = {},
  )

  all_inputs = []
  image_specs = []
  if ctx.attr.images:
    # Compute the set of layers from the image_targets.
    image_target_dict = _string_to_label(
        ctx.attr.image_targets, ctx.attr.image_target_strings)
    image_files_dict = _string_to_label(
        ctx.files.image_targets, ctx.attr.image_target_strings)

    # Walk the collection of images passed and for each key/value pair
    # collect the parts to pass to the resolver as --image_spec arguments.
    # Each images entry results in a single --image_spec argument.
    # As part of this walk, we also collect all of the image's input files
    # to include as runfiles, so they are accessible to be pushed.
    for tag in ctx.attr.images:
      target = ctx.attr.images[tag]
      image = _get_layers(ctx, image_target_dict[target], image_files_dict[target])

      image_spec = {"name": tag}
      if image.get("legacy"):
        image_spec["tarball"] = image["legacy"]
        all_inputs += [image["legacy"]]

      blobsums = image.get("blobsum", [])
      image_spec["digest"] = ",".join([f.short_path for f in blobsums])
      all_inputs += blobsums

      blobs = image.get("zipped_layer", [])
      image_spec["layer"] = ",".join([f.short_path for f in blobs])
      all_inputs += blobs

      image_spec["config"] = image["config"].short_path
      all_inputs += [image["config"]]

      image_specs += [";".join([
        "%s=%s" % (k, v)
        for (k, v) in image_spec.items()
      ])]

  ctx.action(
      command = """cat > {resolve_script} <<"EOF"
#!/bin/bash -e
{resolver} --template {yaml} {images}
EOF""".format(
        resolver = ctx.executable._resolver.short_path,
        yaml = ctx.outputs.yaml.short_path,
        images = " ".join([
          # Quote the parameter otherwise semi-colons complete the command.
          "--image_spec='%s'" % spec
          for spec in image_specs
        ]),
        resolve_script = ctx.outputs.executable.path,
      ),
      inputs = [],
      outputs = [ctx.outputs.executable],
      mnemonic = "ResolveScript"
  )

  return struct(runfiles = ctx.runfiles(files = [
    ctx.executable._resolver,
    ctx.outputs.yaml,
  ] + all_inputs))

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
        "images": attr.string_dict(),
        # Implicit dependencies.
        "image_targets": attr.label_list(allow_files = True),
        "image_target_strings": attr.string_list(),
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
    images: a dictionary from fully-qualified tag to label.
  """
  for reserved in ["image_targets", "image_target_strings", "resolved"]:
    if reserved in kwargs:
      fail("reserved for internal use by docker_bundle macro", attr=reserved)

  kwargs["image_targets"] = list(set(kwargs.get("images", {}).values()))
  kwargs["image_target_strings"] = list(set(kwargs.get("images", {}).values()))

  _k8s_object(name=name, **kwargs)
