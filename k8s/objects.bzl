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
        runfiles.extend(list(obj.default_runfiles.files.to_list()))

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(files = runfiles),
        ),
    ]

_run_all = rule(
    attrs = {
        "delimiter": attr.string(default = ""),
        "objects": attr.label_list(
            cfg = "target",
        ),
        "_template": attr.label(
            default = Label("//k8s:resolve-all.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    implementation = _run_all_impl,
)

def _reverse(lis, reverse = False):
    """Returns a reversed list if if reverse is true

    Args:
      lis: The list to be potentially reversed
      reverse: If True the provided list will be reversed
    """
    if reverse:
        return reversed(lis)
    else:
        return lis

def _cmd_objects(cmd, objects, reverse = False):
    """Returns either a list or a select statement of objects for the provided cmd

    Args:
      cmd: name of the command that will be appended to each object
      objects: The objects that will get the cmd appended
      reverse: If the order of the objects should be reversed or not
    """
    if type(objects) == "dict":
        return select({k: [x + cmd for x in _reverse(v, reverse)] for k, v in objects.items()})
    else:
        return [x + cmd for x in _reverse(objects, reverse)]

def k8s_objects(name, objects, **kwargs):
    """Interact with a collection of K8s objects.

    Args:
      name: name of the rule.
      objects: list or dict of k8s_object rules. A dict will be converted into a select statement.
      **kwargs: Pass through other arguments accepted by k8s_object.
    """

    # TODO(mattmoor): We may have to normalize the labels that come
    # in through objects.
    _run_all(name = name, objects = _cmd_objects("", objects), delimiter = "echo ---\n", **kwargs)
    _run_all(name = name + ".resolve", objects = _cmd_objects("", objects), delimiter = "echo ---\n", **kwargs)
    _run_all(name = name + ".create", objects = _cmd_objects(".create", objects), **kwargs)
    _run_all(name = name + ".delete", objects = _cmd_objects(".delete", objects, True), **kwargs)
    _run_all(name = name + ".replace", objects = _cmd_objects(".replace", objects), **kwargs)
    _run_all(name = name + ".apply", objects = _cmd_objects(".apply", objects), **kwargs)
