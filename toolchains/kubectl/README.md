# kubectl Toolchain

## Overview
This section describes how the `kubectl` tool is configured using a toolchain
rule. At the moment, the tool's configuration does one of the following:

1. Detect the path to the `kubectl` tool (default).
2. Build the `kubectl` tool from source.

If you want to build the `kubectl` tool from source you will
need to add to your `WORKSPACE` file the following lines (Note:
The call to `kubectl_configure` must be before the call to
`k8s_repositories`):

```python
load("//toolchains/kubectl:kubectl_configure.bzl", "kubectl_configure")

kubectl_configure(name="k8s_config", build_srcs=True)
k8s_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")

go_rules_dependencies()
go_register_toolchains()
```

By default, the kubectl sources pulled in is defined [here](defaults.bzl).
However, if you wanted to use release v1.13.1, call `kubectl_configure` as
follows:

```python
kubectl_configure(mame="k8s_config", build_srcs=True,
    k8s_commit = "v1.13.1",
    # Run wget https://github.com/kubernetes/kubernetes/archive/v1.13.1.tar.gz
    # to download v1.13.1.tar.gz and run sha256sum on the downloaded archive
    # to get the value of this attribute.
    k8s_sha256 = "677d2a5021c3826a9122de5a9c8827fed4f28352c6abacb336a1a5a007e434b7",
    # Open the archive downloaded from https://github.com/kubernetes/kubernetes/archive/v1.13.1.tar.gz.
    # This attribute is the name of the top level directory in that archive.
    k8s_prefix = "kubernetes-1.13.1"
)
```

Note that by default the `k8s_repositories()` calls `kubectl_configure` if it
hasn't already been called. This configures a `kubectl_toolchain` that looks for
the `kubectl` tool in the sytem path. If no `kubectl` tool is found, trying to
execute `bazel run` for any targets will not work.

*NOTE: The lines above are required to create the dependencies and register
the toolchain needed to build kubectl. If your project already imports*
`io_bazel_rules_go` *make sure its at v0.16.1 or above.*

*NOTE: We are currently experimenting with toolchain features in these rules
so there will be changes upcoming to how this configuration is performed.*

## Using the kubectl toolchain

The information below will be helpful if:

1. You want to write a new Bazel rule that uses the `kubectl` tool.
2. You want to extend rules from this repository that are using the kubectl
toolchain. You will know if your underlying rules depend on the kubectl
toolchain and the toolchain is not properly configured if you get one of the
following errors
   ```
   In <rule name> rule <build target>, toolchain type
   @io_bazel_rules_k8s//toolchains/kubectl:toolchain_type was requested but only types [] are configured
   ```
   or
   ```
   ERROR: While resolving toolchains for target <build target>: no matching toolchains found for types @io_bazel_rules_k8s//toolchains/kubectl:toolchain_type
   ```
   or
   ```
   ERROR: Analysis of target '<build target>' failed; build aborted: no such package '@local_k8s_config//': The repository could not be resolved
   ```
First read the official Bazel toolchain docs
[here](https://docs.bazel.build/versions/master/toolchains.html) on how
toolchain rules work. Then, continue reading below.

## How to use the kubectl Toolchain
Register the toolchains exported by this repository in your WORKSPACE and add a
`kubectl_configure` target called "local_k8s_config".
```python
register_toolchains(
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_toolchain",
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_toolchain",
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_windows_toolchain",
)

load("@io_bazel_rules_k8s//toolchains/kubectl:kubectl_configure.bzl", "kubectl_configure")

kubectl_configure(name = "local_k8s_config")
```

Declare the kubectl toolchain as a requirement in your rule
```python
your_rule = rule(
    attrs=...,
    ...
    toolchains=["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"],
    implementation=_impl
)
```

Use the rule as follows in the rule implementation function
```python
def _impl(ctx):
    # Get the KubectlInfo provider
    kubectl_tool_info = ctx.toolchains["@io_bazel_rules_k8s//toolchains/kubectl:toolchain_type"].kubectlinfo
    # Path to the kubectl tool
    kubectl_path = kubectl_tool_info.tool_path
    ...
```
See [kubectl_toolchain.bzl](kubectl_toolchain.bzl) for the definition of the
KubectlInfo provider.
