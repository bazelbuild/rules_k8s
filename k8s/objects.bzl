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
    "@io_bazel_rules_docker//skylib:path.bzl",
    _get_runfile_path = "runfile",
)

def _runfiles(ctx, f):
  return "PYTHON_RUNFILES=${RUNFILES} ${RUNFILES}/%s $@" % _get_runfile_path(ctx, f)

def _run_all_impl(ctx):
  ctx.actions.expand_template(
      template = ctx.file._template,
      substitutions = {
          "%{resolve_statements}": ("\n" + ctx.attr.delimiter).join([
              _runfiles(ctx, exe.files_to_run.executable)
              for exe in ctx.attr.objects
          ]),
      },
      output = ctx.outputs.executable,
  )

  runfiles = [obj.files_to_run.executable for obj in ctx.attr.objects]
  for obj in ctx.attr.objects:
    runfiles += list(obj.default_runfiles.files)

  return struct(runfiles = ctx.runfiles(files = runfiles))

_run_all = rule(
    attrs = {
        "objects": attr.label_list(
            cfg = "target",
        ),
        "_template": attr.label(
            default = Label("//k8s:resolve-all.sh.tpl"),
            single_file = True,
            allow_files = True,
        ),
        "delimiter": attr.string(default = ""),
    },
    executable = True,
    implementation = _run_all_impl,
)

def k8s_objects(name, objects, **kwargs):
  """Interact with a collection of K8s objects.

  Args:
    name: name of the rule.
    objects: list of k8s_object rules.
  """

  # TODO(mattmoor): We may have to normalize the labels that come
  # in through objects.

  _run_all(name=name, objects=objects, delimiter="echo ---\n", **kwargs)
  _run_all(name=name + ".create", objects=[x + ".create" for x in objects], **kwargs)
  _run_all(name=name + ".delete", objects=[x + ".delete" for x in reversed(objects)], **kwargs)
  _run_all(name=name + ".replace", objects=[x + ".replace" for x in objects], **kwargs)
  _run_all(name=name + ".apply", objects=[x + ".apply" for x in objects], **kwargs)
