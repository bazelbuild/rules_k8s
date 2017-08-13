# Bazel Kubernetes Rules

[![Build Status](http://ci.bazel.io/buildStatus/icon?job=rules_k8s)](http://ci.bazel.io/job/rules_k8s)

## Rules

* Coming Soon!

## Overview

This is a placeholder repository for holding rules to interact with Kubernetes
constructs.

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

## SkyDoc

TODO: Link to skydoc documentation for `rules_k8s`.
