# kubectl Toolchain

## Overview
This section describes how the `kubectl` tool is configured using a toolchain rule.
At the moment, the tool's configuration only detects the path to the `kubectl` tool.

The information below will be helpful if:

1. You wish to write a new Bazel rule that uses the `kubectl` tool.
2. You wish to extend rules from this repository that are using the kubectl toolchain. You will know if your underlying rules depend on the kubectl toolchain and the toolchain is not properly configured if you get one of the following errors
   ```
   In <rule name> rule <build target>, toolchain type
   @io_bazel_rules_k8s//toolchains/kubectl:toolchain_type was requested but only types [] are configured
   ```
   or
   ```
   **ERROR:** While resolving toolchains for target <build target>: no matching toolchains found for types @io_bazel_rules_k8s//toolchains/kubectl:toolchain_type
   ```
   or
   ```
   **ERROR:** Analysis of target '<build target>' failed; build aborted: no such package '@local_k8s_config//': The repository could not be resolved
   ```
First read the official Bazel toolchain docs [here](https://docs.bazel.build/versions/master/toolchains.html) on how toolchain rules work. Then, continue reading below.

## How to use the kubectl Toolchain
Register the toolchains exported by this repository in your WORKSPACE and add a `kubectl_configure` target called "local_k8s_config".
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
See [kubectl_toolchain.bzl](kubectl_toolchain.bzl) for the definition of the KubectlInfo provider.
