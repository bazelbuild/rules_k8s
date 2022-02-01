# kubectl Toolchain

## Overview
This section describes how the `kubectl` tool is configured using a toolchain
rule. At the moment, the tool's configuration does one of the following:

1. Detect the path to the `kubectl` tool (default).
2. Build the `kubectl` tool from source.
3. Download a `kubectl` prebuilt binary not on the system path.

### Use a kubectl built from source
If you want to build the `kubectl` tool from source you will
need to add to your `WORKSPACE` file the following lines (Note:
The call to `kubectl_configure` must be before the call to
`k8s_repositories`):

```python
load("@io_bazel_rules_k8s//toolchains/kubectl:kubectl_configure.bzl", "kubectl_configure")

kubectl_configure(name="k8s_config", build_srcs=True)
k8s_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")

go_rules_dependencies()
go_register_toolchains()
```

By default, the kubectl sources and kubernetes repository infrastructure tools
pulled in is defined [here](defaults.bzl). To use e.g., kubernetes release
v1.13.1, call `kubectl_configure` as follows:

```python
kubectl_configure(name="k8s_config", build_srcs=True,
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

To use e.g., kubernetes repository infrastructure tools at commit
`b4bc4f1552c7fc1d4654753ca9b0e5e13883429f`, call `kubectl_configure` as follows:

```python
kubectl_configure(name="k8s_config", build_srcs=True,
    k8s_repo_tools_commit = "b4bc4f1552c7fc1d4654753ca9b0e5e13883429f",
    # Run wget https://github.com/kubernetes/kubernetes/archive/b4bc4f1552c7fc1d4654753ca9b0e5e13883429f.tar.gz
    # to download b4bc4f1552c7fc1d4654753ca9b0e5e13883429f.tar.gz and run
    # sha256sum on the downloaded archive to get the value of this attribute.
    k8s_repo_tools_sha256 = "21160531ea8a9a4001610223ad815622bf60671d308988c7057168a495a7e2e8",
    # Open the archive downloaded from https://github.com/kubernetes/kubernetes/archive/b4bc4f1552c7fc1d4654753ca9b0e5e13883429f.tar.gz
    # This attribute is the name of the top level directory in that archive.
    k8s_repo_tools_prefix = "repo-infra-b4bc4f1552c7fc1d4654753ca9b0e5e13883429f"
)
```

The use e.g., kubernetes release v1.13.1 with repository infrastructure tools
at commit `b4bc4f1552c7fc1d4654753ca9b0e5e13883429f`, call `kubectl_configure`
as follows:

```python
kubectl_configure(name="k8s_config", build_srcs=True,
    k8s_commit = "v1.13.1",
    k8s_sha256 = "677d2a5021c3826a9122de5a9c8827fed4f28352c6abacb336a1a5a007e434b7",
    k8s_prefix = "kubernetes-1.13.1",
    k8s_repo_tools_commit = "b4bc4f1552c7fc1d4654753ca9b0e5e13883429f",
    k8s_repo_tools_sha256 = "21160531ea8a9a4001610223ad815622bf60671d308988c7057168a495a7e2e8",
    k8s_repo_tools_prefix = "repo-infra-b4bc4f1552c7fc1d4654753ca9b0e5e13883429f"
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

*NOTE: If you change the default kubernetes source repository version via the
`k8s_commit` attribute to `kubectl_configure`, you must also find out the right
version of the kubernetes repository tools infrastructure the new kubernetes
source repository is compatible with. Look at the `http_archive` invocation in
https://github.com/kubernetes/kubernetes/blob/{k8s_commit}/build/root/WORKSPACE
for the `@io_kubernetes_build` to get the commit pin, sha256 and prefix values.*

### Download a custom kubectl binary

If you want to download a standard binary released by the kubernetes project,
get the URL and SHA256 for the binary for your platform from [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl).
For example, if you want to use kubectl v1.10.0 on a x86 64 bit Linux platform,
add to your `WORKSPACE` file the following lines (Note: The call to
`kubectl_configure` must be before the  call to `k8s_repositories`):

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "io_bazel_rules_docker",
    commit = "{HEAD}",
    remote = "https://github.com/bazelbuild/rules_docker.git",
)

load(
  "@io_bazel_rules_docker//container:container.bzl",
  container_repositories = "repositories",
)

container_repositories()

# This requires rules_docker to be fully instantiated before
# it is pulled in.
git_repository(
    name = "io_bazel_rules_k8s",
    commit = "{HEAD}",
    remote = "https://github.com/bazelbuild/rules_k8s.git",
)

load("@io_bazel_rules_k8s//toolchains/kubectl:kubectl_configure.bzl", "kubectl_configure")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
# Download the v1.10.0 kubectl binary for the Linux x86 64 bit platform.
http_file(
    name="k8s_binary",
    downloaded_file_path = "kubectl",
    sha256="49f7e5791d7cd91009c728eb4dc1dbf9ee1ae6a881be6b970e631116065384c3",
    executable=True,
    urls=["https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/linux/amd64/kubectl"],
)
# Configure the kubectl toolchain to use the downloaded prebuilt v1.10.0
# kubectl binary.
kubectl_configure(name="k8s_config", kubectl_path="@k8s_binary//file")
k8s_repositories()
```



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
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_amd64_toolchain",
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_arm64_toolchain",
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_linux_s390x_toolchain",
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_amd64_toolchain",
    "@io_bazel_rules_k8s//toolchains/kubectl:kubectl_osx_arm64_toolchain",
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
