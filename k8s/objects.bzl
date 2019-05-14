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

RunAllInfo = provider()

def _runfiles(ctx, f):
    return "PYTHON_RUNFILES=${RUNFILES} ${RUNFILES}/%s $@" % _get_runfile_path(ctx, f)

def _run_all_aspect_impl(target, ctx):
    files_to_run = []
    runfiles = ctx.runfiles()
    if ctx.rule.kind.startswith("_k8s_object_"):
        files_to_run = [target.files_to_run.executable]
        runfiles = target.default_runfiles
    transitive_files_to_run = []
    if hasattr(ctx.rule.attr, "objects"):
        for obj in ctx.rule.attr.objects:
            if RunAllInfo in obj:
                transitive_files_to_run.append(obj[RunAllInfo].files_to_run)
                runfiles = runfiles.merge(obj[RunAllInfo].runfiles)
    return [
        RunAllInfo(
            files_to_run = depset(files_to_run, transitive = transitive_files_to_run),
            runfiles = runfiles,
        ),
    ]

_run_all_aspect = aspect(
    implementation = _run_all_aspect_impl,
    attr_aspects = ["objects"],
)

def _run_all_impl(ctx):
    runfiles = ctx.runfiles()
    transitive_files_to_run = []
    for obj in ctx.attr.objects:
        if RunAllInfo in obj:
            transitive_files_to_run.append(obj[RunAllInfo].files_to_run)
            runfiles = runfiles.merge(obj[RunAllInfo].runfiles)
    files_to_run = depset([], transitive = transitive_files_to_run)

    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = {
            "%{resolve_statements}": ("\n" + ctx.attr.delimiter).join([
                _runfiles(ctx, f)
                for f in files_to_run.to_list()
            ]),
        },
        output = ctx.outputs.executable,
    )

    return [
        DefaultInfo(
            runfiles = runfiles,
        ),
    ]

_run_all = rule(
    attrs = {
        "delimiter": attr.string(default = ""),
        "objects": attr.label_list(
            cfg = "target",
            aspects = [_run_all_aspect],
        ),
        "_template": attr.label(
            default = Label("//k8s:resolve-all.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    implementation = _run_all_impl,
)

def k8s_objects(name, objects, **kwargs):
    """Interact with a collection of K8s objects.

    Args:
      name: name of the rule.
      objects: list of k8s_object rules.
      **kwargs: Pass through other arguments accepted by k8s_object.
    """

    # TODO(mattmoor): We may have to normalize the labels that come
    # in through objects.

    _run_all(name = name, objects = objects, delimiter = "echo ---\n", **kwargs)
    _run_all(name = name + ".create", objects = [x + ".create" for x in objects], **kwargs)
    _run_all(name = name + ".delete", objects = [x + ".delete" for x in reversed(objects)], **kwargs)
    _run_all(name = name + ".replace", objects = [x + ".replace" for x in objects], **kwargs)
    _run_all(name = name + ".apply", objects = [x + ".apply" for x in objects], **kwargs)
