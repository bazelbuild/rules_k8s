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

java_binary(
    name = "client",
    srcs = ["HelloClient.java"],
    main_class = "io.bazel.rules_k8s.examples.helloworld.java.client.HelloClient",
    deps = [
        "//examples/hellogrpc/proto:simple_java_grpc",
        "@build_stack_rules_proto//java:grpc_netty",
    ],
)
