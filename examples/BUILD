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

load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_library")
load("@io_bazel_rules_k8s//k8s:cluster.bzl", "k8s_cluster")
load("@io_bazel_rules_k8s//k8s:clusters.bzl", "k8s_clusters")
load("@subpar//:subpar.bzl", "par_binary")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

jsonnet_library(
    name = "deploy_lib",
    srcs = ["deployment.libsonnet"],
)

jsonnet_library(
    name = "container_lib",
    srcs = ["container.libsonnet"],
)

par_binary(
    name = "e2e_gc",
    srcs = ["e2e_gc.py"],
    main = "e2e_gc.py",
    python_version = "PY3",
)

k8s_clusters(
    name = "clusters",
    clusters = [
        ":gke_rules-k8s_us-central1-f_testing",
        ":minikube",
    ],
)

k8s_cluster(
    name = "gke_rules-k8s_us-central1-f_testing",
    cluster = "gke_rules-k8s_us-central1-f_testing",
    context = "gke_rules-k8s_us-central1-f_testing",
    image_chroot = "us.gcr.io/rules_k8s/{BUILD_USER}",
    kubeconfig = ":kubeconfig",
)

k8s_cluster(
    name = "minikube",
    cluster = "minikube",
    context = "minikube",
    image_chroot = "localhost:5000/rules_k8s",
)

# Generate an empty kubeconfig for testing
genrule(
    name = "kubeconfig",
    srcs = [],
    outs = ["kubeconfig.out"],
    cmd = "touch $@",
)
