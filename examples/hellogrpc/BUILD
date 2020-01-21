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

load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_to_json")
load("@io_bazel_rules_k8s//k8s:objects.bzl", "k8s_objects")
load("@k8s_deploy//:defaults.bzl", "k8s_deploy")
load("@k8s_service//:defaults.bzl", "k8s_service")
load("@py_deps//:requirements.bzl", "requirement")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

k8s_deploy(
    name = "staging-deployment",
    template = "deployment.yaml",
)

k8s_deploy(
    name = "staging-deployment-with-kubeconfig",
    kubeconfig = ":kubeconfig",
    template = "deployment.yaml",
)

k8s_service(
    name = "staging-service",
    template = "service.yaml",
)

config_setting(
    name = "is_prod",
    define_values = {"environment": "staging"},
    visibility = ["//visibility:public"],
)

k8s_objects(
    name = "staging",
    args = [
        "--v=2",
    ],
    objects = {
        ":is_prod": [],
        "//conditions:default": [
            ":staging-deployment",
            ":staging-service",
        ],
    },
)

jsonnet_to_json(
    name = "deployment",
    src = "deployment.jsonnet",
    outs = ["deployment.json"],
    deps = [
        "//examples:container_lib",
        "//examples:deploy_lib",
    ],
)

# Generate an empty kubeconfig for testing
genrule(
    name = "kubeconfig",
    srcs = [],
    outs = ["kubeconfig.out"],
    cmd = "touch $@",
)

# Verify that deployment.json == deployment.yaml
py_test(
    name = "deployment_test",
    srcs = ["deployment_test.py"],
    data = [
        ":deployment.json",
        ":deployment.yaml",
    ],
    deps = [
        requirement("PyYAML"),
    ],
)
