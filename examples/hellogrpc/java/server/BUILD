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
package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache 2.0

load("@io_bazel_rules_docker//java:image.bzl", "java_image")

java_image(
    name = "server",
    srcs = ["HelloServer.java"],
    main_class = "io.bazel.rules_k8s.examples.helloworld.java.server.HelloServer",
    deps = [
        "//examples/hellogrpc/proto:simple_java_grpc",
        "@build_stack_rules_proto//java:grpc_netty",
    ],
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging",
    images = {
        "us.gcr.io/not-my-project/hello-grpc:staging": ":server",
    },
    template = "//examples/hellogrpc:deployment.json",
)
