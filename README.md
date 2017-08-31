# Bazel Kubernetes Rules

Travis CI | Bazel CI
:---: | :---:
[![Build Status](https://travis-ci.org/bazelbuild/rules_k8s.svg?branch=master)](https://travis-ci.org/bazelbuild/rules_k8s) | [![Build Status](http://ci.bazel.io/buildStatus/icon?job=rules_k8s)](http://ci.bazel.io/job/rules_k8s)

## Rules

* [k8s_object](#k8s_object)

## Overview


This repository contains rules for interacting with Kubernetes
configurations / clusters.

## Setup

Add the following to your `WORKSPACE` file to add the necessary external dependencies:

```python
git_repository(
    name = "io_bazel_rules_k8s",
    remote = "https://github.com/bazelbuild/rules_k8s.git",
    commit = "{HEAD}",
)

# TODO(mattmoor): We should be careful to enable folks to do stuff with the template
# portions of this without requiring a rules_docker dependency (if we can).
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
