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

load("@io_bazel_rules_k8s//k8s:object.bzl", "k8s_object")
load("@py_deps//:requirements.bzl", "requirement")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

k8s_object(
    name = "image_stamping",
    # Build images with the same container
    images = {
        "index.docker.io/parsec86/{REPOSITORY}:{STABLE_GIT_COMMIT}": "//examples/stamping/go:go-container",
    },
    # K8s deployment template with a stamping variable to replace
    template = ":deployment.yaml",
)

k8s_object(
    name = "substitution_stamping",
    # Stamp values can also be used in substitutions
    substitutions = {
        "%{e2e_namespace}": "{STABLE_E2E_NAMESPACE}",
        "%{key}": "foo",
    },
    # K8s deployment template with a stamping variable to replace
    template = ":configmap.yaml",
)

py_test(
    name = "substitution_test",
    srcs = ["substitution_test.py"],
    data = [":substitution_stamping"],
    python_version = "PY3",
    deps = [
        requirement("pyyaml"),
    ],
)
