proto_library(
    name = "simple_proto",
    srcs = ["simple.proto"],
    visibility = ["//visibility:public"],
)

load("@build_stack_rules_proto//cpp:cpp_grpc_library.bzl", "cpp_grpc_library")

cpp_grpc_library(
    name = "simple_cc_grpc",
    visibility = ["//examples/hellogrpc/cc:__subpackages__"],
    deps = [":simple_proto"],
)

load("@build_stack_rules_proto//java:java_grpc_library.bzl", "java_grpc_library")

java_grpc_library(
    name = "simple_java_grpc",
    visibility = ["//examples/hellogrpc/java:__subpackages__"],
    deps = [":simple_proto"],
)

load("@build_stack_rules_proto//go:go_grpc_library.bzl", "go_grpc_library")

go_grpc_library(
    name = "simple_go_grpc",
    importpath = "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go",
    visibility = ["//examples/hellogrpc/go:__subpackages__"],
    deps = [":simple_proto"],
)

load("@build_stack_rules_proto//python:python_grpc_library.bzl", "python_grpc_library")

python_grpc_library(
    name = "simple_python_grpc",
    visibility = ["//examples/hellogrpc/py:__subpackages__"],
    deps = [":simple_proto"],
)
