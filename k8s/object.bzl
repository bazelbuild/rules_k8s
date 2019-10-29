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
    "@io_bazel_rules_docker//container:layer_tools.bzl",
    _get_layers = "get_from_target",
    _layer_tools = "tools",
)
load(
    "@io_bazel_rules_docker//skylib:label.bzl",
    _string_to_label = "string_to_label",
)
load(
    "@io_bazel_rules_docker//skylib:path.bzl",
    _get_runfile_path = "runfile",
)

def _runfiles(ctx, f):
    return "${RUNFILES}/%s" % _get_runfile_path(ctx, f)

def _deduplicate(iterable):
    """Performs a deduplication (similar to `list(set(...))`)

    This is necessary because `set` is not available in Skylark.
    """
    return {k: None for k in iterable}.keys()

def _add_dicts(*dicts):
    """Creates a new dict with a union of the elements of the arguments
    """
    result = {}
    for d in dicts:
        result.update(d)
    return result

def _impl(ctx):
    """Core implementation of k8s_object."""

    all_inputs = []
    image_specs = []
    if ctx.attr.images:
        # Compute the set of layers from the image_targets.
        image_target_dict = _string_to_label(
            ctx.attr.image_targets,
            ctx.attr.image_target_strings,
        )

        # Walk the collection of images passed and for each key/value pair
        # collect the parts to pass to the resolver as --image_spec arguments.
        # Each images entry results in a single --image_spec argument.
        # As part of this walk, we also collect all of the image's input files
        # to include as runfiles, so they are accessible to be pushed.
        for tag in ctx.attr.images:
            resolved_tag = ctx.expand_make_variables("tag", tag, {})
            target = ctx.attr.images[tag]
            image = _get_layers(ctx, ctx.label.name, image_target_dict[target])

            image_spec = {"name": resolved_tag}
            if image.get("legacy"):
                image_spec["tarball"] = _runfiles(ctx, image["legacy"])
                all_inputs += [image["legacy"]]

            blobsums = image.get("blobsum", [])
            image_spec["digest"] = ",".join([_runfiles(ctx, f) for f in blobsums])
            all_inputs += blobsums

            diff_ids = image.get("diff_id", [])
            image_spec["diff_id"] = ",".join([_runfiles(ctx, f) for f in diff_ids])
            all_inputs += diff_ids

            blobs = image.get("zipped_layer", [])
            image_spec["compressed_layer"] = ",".join([_runfiles(ctx, f) for f in blobs])
            all_inputs += blobs

            uncompressed_blobs = image.get("unzipped_layer", [])
            image_spec["uncompressed_layer"] = ",".join([_runfiles(ctx, f) for f in uncompressed_blobs])
            all_inputs += uncompressed_blobs

            image_spec["config"] = _runfiles(ctx, image["config"])
            all_inputs += [image["config"]]

            # Quote the semi-colons so they don't complete the command.
            image_specs += ["';'".join([
                "%s=%s" % (k, v)
                for (k, v) in image_spec.items()
            ])]

    # Add workspace_status_command files to the args that are pushed to the resolver and adds the
    # files to the runfiles so they are available to the resolver executable.
    stamp_inputs = [ctx.info_file, ctx.version_file]
    stamp_args = " ".join(["--stamp-info-file=%s" % _runfiles(ctx, f) for f in stamp_inputs])
    all_inputs += stamp_inputs

    image_chroot_arg = ctx.attr.image_chroot
    image_chroot_arg = ctx.expand_make_variables("image_chroot", image_chroot_arg, {})
    if "{" in ctx.attr.image_chroot:
        image_chroot_file = ctx.actions.declare_file(ctx.label.name + ".image-chroot-name")
        _resolve(ctx, ctx.attr.image_chroot, image_chroot_file)
        image_chroot_arg = "$(cat %s)" % _runfiles(ctx, image_chroot_file)
        all_inputs += [image_chroot_file]

    ctx.actions.expand_template(
        template = ctx.file.template,
        substitutions = {
            key: ctx.expand_make_variables(key, value, {})
            for (key, value) in ctx.attr.substitutions.items()
        },
        output = ctx.outputs.substituted,
    )

    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = {
            "%{image_chroot}": image_chroot_arg,
            "%{images}": " ".join([
                "--image_spec=%s" % spec
                for spec in image_specs
            ]),
            "%{resolver_args}": " ".join(ctx.attr.resolver_args or []),
            "%{resolver}": _runfiles(ctx, ctx.executable.resolver),
            "%{stamp_args}": stamp_args,
            "%{yaml}": _runfiles(ctx, ctx.outputs.substituted),
        },
        output = ctx.outputs.executable,
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = [
                    ctx.executable.resolver,
                    ctx.outputs.substituted,
                ] + all_inputs,
                transitive_files = ctx.attr.resolver[DefaultInfo].default_runfiles.files,
            ),
        ),
    ]

def _resolve(ctx, string, output):
    stamps = [ctx.info_file, ctx.version_file]
    args = ctx.actions.args()
    args.add_all(stamps, format_each = "--stamp-info-file=%s")
    args.add(string, format = "--format=%s")
    args.add(output, format = "--output=%s")
    ctx.actions.run(
        executable = ctx.executable._stamper,
        arguments = [args],
        inputs = stamps,
        tools = [ctx.executable._stamper],
        outputs = [output],
        mnemonic = "Stamp",
    )

def _common_impl(ctx):
    files = [ctx.executable.resolver]

    cluster_arg = ctx.attr.cluster
    cluster_arg = ctx.expand_make_variables("cluster", cluster_arg, {})
    if "{" in ctx.attr.cluster:
        cluster_file = ctx.actions.declare_file(ctx.label.name + ".cluster-name")
        _resolve(ctx, ctx.attr.cluster, cluster_file)
        cluster_arg = "$(cat %s)" % _runfiles(ctx, cluster_file)
        files += [cluster_file]

    context_arg = ctx.attr.context
    context_arg = ctx.expand_make_variables("context", context_arg, {})
    if "{" in ctx.attr.context:
        context_file = ctx.actions.declare_file(ctx.label.name + ".context-name")
        _resolve(ctx, ctx.attr.context, context_file)
        context_arg = "$(cat %s)" % _runfiles(ctx, context_file)
        files += [context_file]

    user_arg = ctx.attr.user
    user_arg = ctx.expand_make_variables("user", user_arg, {})
    if "{" in ctx.attr.user:
        user_file = ctx.actions.declare_file(ctx.label.name + ".user-name")
        _resolve(ctx, ctx.attr.user, user_file)
        user_arg = "$(cat %s)" % _runfiles(ctx, user_file)
        files += [user_file]

    namespace_arg = ctx.attr.namespace
    namespace_arg = ctx.expand_make_variables("namespace", namespace_arg, {})
    if "{" in ctx.attr.namespace:
        namespace_file = ctx.actions.declare_file(ctx.label.name + ".namespace-name")
        _resolve(ctx, ctx.attr.namespace, namespace_file)
        namespace_arg = "$(cat %s)" % _runfiles(ctx, namespace_file)
        files += [namespace_file]

    if namespace_arg:
        namespace_arg = "--namespace=\"" + namespace_arg + "\""

    if ctx.file.kubeconfig:
        kubeconfig_arg = _runfiles(ctx, ctx.file.kubeconfig)
        files += [ctx.file.kubeconfig]
    else:
        kubeconfig_arg = ""

    kubectl_tool_info = ctx.toolchains["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"].kubectlinfo
    extrafiles = depset()
    if kubectl_tool_info.tool_path == "" and not kubectl_tool_info.tool_target:
        # If tool_path is empty and tool_target is None then there is no local
        # kubectl tool, we will just print a nice error message if the user
        # attempts to do bazel run
        ctx.actions.write(
            content = ("echo kubectl toolchain was not properly configured so %s cannot be executed." % ctx.attr.name),
            output = ctx.outputs.executable,
        )
    else:
        kubectl_tool = kubectl_tool_info.tool_path
        if kubectl_tool_info.tool_target:
            kubectl_tool = _runfiles(ctx, kubectl_tool_info.tool_target.files.to_list()[0])
            extrafiles = depset(transitive = [kubectl_tool_info.tool_target.files])

        substitutions = {
            "%{cluster}": cluster_arg,
            "%{context}": context_arg,
            "%{kind}": ctx.attr.kind,
            "%{kubeconfig}": kubeconfig_arg,
            "%{kubectl_tool}": kubectl_tool,
            "%{namespace_arg}": namespace_arg,
            "%{user}": user_arg,
        }

        if hasattr(ctx.executable, "resolved"):
            substitutions["%{resolve_script}"] = _runfiles(ctx, ctx.executable.resolved)
            files += [ctx.executable.resolved]
            extrafiles = depset(transitive = [ctx.attr.resolved[DefaultInfo].default_runfiles.files, extrafiles])

        if hasattr(ctx.executable, "reversed"):
            substitutions["%{reverse_script}"] = _runfiles(ctx, ctx.executable.reversed)
            files += [ctx.executable.reversed]
            extrafiles = depset(transitive = [ctx.attr.reversed[DefaultInfo].default_runfiles.files, extrafiles])

        if hasattr(ctx.files, "unresolved"):
            substitutions["%{unresolved}"] = _runfiles(ctx, ctx.file.unresolved)
            files += ctx.files.unresolved

        ctx.actions.expand_template(
            template = ctx.file._template,
            substitutions = substitutions,
            output = ctx.outputs.executable,
        )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(files = files, transitive_files = extrafiles),
        ),
    ]

_common_attrs = {
    # We allow cluster to be omitted, and we just
    # don't expose the extra actions.
    "cluster": attr.string(),
    "context": attr.string(),
    "image_chroot": attr.string(),
    # This is only needed for describe.
    "kind": attr.string(),
    "kubeconfig": attr.label(
        allow_single_file = True,
    ),
    "namespace": attr.string(),
    "resolver": attr.label(
        default = Label("//k8s/go/cmd/resolver"),
        cfg = "host",
        executable = True,
        allow_files = True,
    ),
    # Extra arguments to pass to the resolver.
    "resolver_args": attr.string_list(),
    "user": attr.string(),
    "_stamper": attr.label(
        default = Label("//k8s:stamper"),
        cfg = "host",
        executable = True,
        allow_files = True,
    ),
}

def _reverse(ctx):
    """Implementation of _reversed."""
    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = {
            "%{reverser}": _runfiles(ctx, ctx.executable.reverser),
            "%{yaml}": _runfiles(ctx, ctx.file.template),
        },
        output = ctx.outputs.executable,
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = [
                    ctx.executable.reverser,
                    ctx.file.template,
                ],
                transitive_files = ctx.attr.reverser[DefaultInfo].default_runfiles.files,
            ),
        ),
    ]

_reversed = rule(
    attrs = _add_dicts(
        {
            "reverser": attr.label(
                default = Label("//k8s:reverser"),
                cfg = "host",
                executable = True,
                allow_files = True,
            ),
            "template": attr.label(
                allow_single_file = [
                    ".yaml",
                    ".json",
                ],
                mandatory = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:reverse.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
        _layer_tools,
    ),
    executable = True,
    implementation = _reverse,
)

_k8s_object = rule(
    attrs = _add_dicts(
        {
            "image_target_strings": attr.string_list(),
            # Implicit dependencies.
            "image_targets": attr.label_list(allow_files = True),
            "images": attr.string_dict(),
            "substitutions": attr.string_dict(),
            "template": attr.label(
                allow_single_file = [
                    ".yaml",
                    ".json",
                ],
                mandatory = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:resolve.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
        _layer_tools,
    ),
    executable = True,
    outputs = {
        "substituted": "%{name}.substituted.yaml",
    },
    implementation = _impl,
)

_k8s_object_apply = rule(
    attrs = _add_dicts(
        {
            "resolved": attr.label(
                cfg = "target",
                executable = True,
                allow_files = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:apply.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
    ),
    executable = True,
    toolchains = ["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"],
    implementation = _common_impl,
)

_k8s_object_create = rule(
    attrs = _add_dicts(
        {
            "resolved": attr.label(
                cfg = "target",
                executable = True,
                allow_files = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:create.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
    ),
    executable = True,
    toolchains = ["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"],
    implementation = _common_impl,
)

_k8s_object_replace = rule(
    attrs = _add_dicts(
        {
            "resolved": attr.label(
                cfg = "target",
                executable = True,
                allow_files = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:replace.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
    ),
    executable = True,
    toolchains = ["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"],
    implementation = _common_impl,
)

_k8s_object_describe = rule(
    attrs = _add_dicts(
        {
            "unresolved": attr.label(
                allow_single_file = [
                    ".yaml",
                    ".json",
                ],
                mandatory = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:describe.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
    ),
    executable = True,
    toolchains = ["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"],
    implementation = _common_impl,
)

_k8s_object_delete = rule(
    attrs = _add_dicts(
        {
            "reversed": attr.label(
                cfg = "target",
                executable = True,
                allow_files = True,
            ),
            "_template": attr.label(
                default = Label("//k8s:delete.sh.tpl"),
                allow_single_file = True,
            ),
        },
        _common_attrs,
    ),
    executable = True,
    toolchains = ["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"],
    implementation = _common_impl,
)

# See "attrs" parameter at https://docs.bazel.build/versions/master/skylark/lib/globals.html#parameters-26
_implicit_attrs = [
    "visibility",
    "restricted_to",
    "compatible_with",
    "deprecation",
    "tags",
    "testonly",
    "features",
]

def _implicit_args_as_dict(**kwargs):
    implicit_args = {}
    for attr_name in _implicit_attrs:
        if attr_name in kwargs:
            implicit_args[attr_name] = kwargs[attr_name]

    return implicit_args

def k8s_object(name, **kwargs):
    """Interact with a K8s object.

    Args:
      name: name of the rule.
      **kwargs: Other arguments accepted by k8s_object build rule.
        cluster: the name of the cluster.
        user: the user which has access to the cluster.
        namespace: the namespace within the cluster.
        kubeconfig: the kubeconfig file to use with kubectl.
        kind: the object kind.
        template: the yaml template to instantiate.
        images: a dictionary from fully-qualified tag to label.
    """
    for reserved in ["image_targets", "image_target_strings", "resolved", "reversed"]:
        if reserved in kwargs:
            fail("reserved for internal use by docker_bundle macro", attr = reserved)

    implicit_args = _implicit_args_as_dict(**kwargs)

    kwargs["image_targets"] = _deduplicate(kwargs.get("images", {}).values())
    kwargs["image_target_strings"] = _deduplicate(kwargs.get("images", {}).values())

    _k8s_object(name = name, **kwargs)
    _reversed(
        name = name + ".reversed",
        template = kwargs.get("template"),
        **implicit_args
    )

    if "cluster" in kwargs or "context" in kwargs:
        _k8s_object_create(
            name = name + ".create",
            resolved = name,
            kind = kwargs.get("kind"),
            cluster = kwargs.get("cluster"),
            context = kwargs.get("context"),
            kubeconfig = kwargs.get("kubeconfig"),
            user = kwargs.get("user"),
            namespace = kwargs.get("namespace"),
            args = kwargs.get("args"),
            **implicit_args
        )
        _k8s_object_delete(
            name = name + ".delete",
            reversed = name + ".reversed",
            kind = kwargs.get("kind"),
            cluster = kwargs.get("cluster"),
            context = kwargs.get("context"),
            kubeconfig = kwargs.get("kubeconfig"),
            user = kwargs.get("user"),
            namespace = kwargs.get("namespace"),
            args = kwargs.get("args"),
            **implicit_args
        )
        _k8s_object_replace(
            name = name + ".replace",
            resolved = name,
            kind = kwargs.get("kind"),
            cluster = kwargs.get("cluster"),
            context = kwargs.get("context"),
            kubeconfig = kwargs.get("kubeconfig"),
            user = kwargs.get("user"),
            namespace = kwargs.get("namespace"),
            args = kwargs.get("args"),
            **implicit_args
        )
        _k8s_object_apply(
            name = name + ".apply",
            resolved = name,
            kind = kwargs.get("kind"),
            cluster = kwargs.get("cluster"),
            context = kwargs.get("context"),
            kubeconfig = kwargs.get("kubeconfig"),
            user = kwargs.get("user"),
            namespace = kwargs.get("namespace"),
            args = kwargs.get("args"),
            **implicit_args
        )
        if "kind" in kwargs:
            _k8s_object_describe(
                name = name + ".describe",
                unresolved = kwargs.get("template"),
                kind = kwargs.get("kind"),
                cluster = kwargs.get("cluster"),
                context = kwargs.get("context"),
                kubeconfig = kwargs.get("kubeconfig"),
                user = kwargs.get("user"),
                namespace = kwargs.get("namespace"),
                args = kwargs.get("args"),
                **implicit_args
            )
