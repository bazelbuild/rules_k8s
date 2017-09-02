# Bazel Kubernetes Rules

Travis CI | Bazel CI
:---: | :---:
[![Build Status](https://travis-ci.org/bazelbuild/rules_k8s.svg?branch=master)](https://travis-ci.org/bazelbuild/rules_k8s) | [![Build Status](http://ci.bazel.io/buildStatus/icon?job=rules_k8s)](http://ci.bazel.io/job/rules_k8s)

## Rules

* [k8s_defaults](#k8s_defaults)
* [k8s_object](#k8s_object)

## Overview

This repository contains rules for interacting with Kubernetes
configurations / clusters.

## Setup

Add the following to your `WORKSPACE` file to add the necessary external dependencies:

```python
git_repository(
    name = "io_bazel_rules_docker",
    commit = "{HEAD}",
    remote = "https://github.com/bazelbuild/rules_docker.git",
)

load(
  "@io_bazel_rules_docker//docker:docker.bzl",
  "docker_repositories",
)

docker_repositories()

# This requires rules_docker to be fully instantiated before
# it is pulled in.
git_repository(
    name = "io_bazel_rules_k8s",
    commit = "{HEAD}",
    remote = "https://github.com/mattmoor/rules_k8s.git",
)

load("@io_bazel_rules_k8s//k8s:k8s.bzl", "k8s_repositories")

k8s_repositories()
```

## Kubernetes Authentication

As is somewhat standard for Bazel, the expectation is that the
`kubectl` toolchain is preconfigured to authenticate with any clusters
you might interact with.

For more information on how to configure `kubectl` authentication, see the
Kubernetes [documentation](https://kubernetes.io/docs/admin/authentication/).

### Container Engine Authentication

For Google Container Engine (GKE), the `gcloud` CLI provides a [simple
command](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)
for setting up authentication:
```shell
gcloud container clusters get-credentials <CLUSTER NAME>
```

## Examples

### Basic "deployment" objects

```python
load("@io_bazel_rules_k8s//k8s:object.bzl", "k8s_object")

k8s_object(
  name = "dev",
  kind = "deployment",

  # A template of a Kubernetes Deployment object yaml.
  template = ":deployment.yaml",
)
```

### Aliasing (e.g. `k8s_deploy`)

In your `WORKSPACE` you can set up aliases for a more readable short-hand:
```python
load("@io_bazel_rules_k8s//k8s:k8s.bzl", "k8s_defaults")

k8s_defaults(
  # This becomes the name of the @repository and the rule
  # you will import in your BUILD files.
  name = "k8s_deploy",
  kind = "deployment",
  cluster = "my-gke-cluster",
)
```

Then in place of the above, you can use the following in your `BUILD` file:

```python
load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
  name = "dev",
  template = ":deployment.yaml",
)
```

<a name="k8s_object"></a>
## k8s_object

```python
k8s_object(name, kind, template)
```

A rule for interacting with Kubernetes objects.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>Unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>kind</code></td>
      <td>
        <p><code>Kind, required</code></p>
        <p>The kind of the Kubernetes object in the yaml.</p>
      </td>
    </tr>
    <tr>
      <td><code>template</code></td>
      <td>
        <p><code>yaml or json file; required</code></p>
        <p>The yaml or json for a Kubernetes object.</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="k8s_defaults"></a>
## k8s_defaults

```python
k8s_defaults(name, kind)
```

A repository rule that allows users to alias `k8s_object` with default values.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>The name of the repository that this rule will create.</p>
        <p>Also the name of rule imported from
	   <code>@name//:defaults.bzl</code></p>
      </td>
    </tr>
    <tr>
      <td><code>kind</code></td>
      <td>
        <p><code>Kind, optional</code></p>
        <p>The kind of objects the alias of <code>k8s_object</code> handles.</p>
      </td>
    </tr>
  </tbody>
</table>
