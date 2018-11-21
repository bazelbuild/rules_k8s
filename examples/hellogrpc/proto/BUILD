proto_library(
    name = "simple_proto",
    srcs = ["simple.proto"],
    visibility = ["//visibility:public"],
)

load("@build_stack_rules_proto//cpp:cpp_grpc_library.bzl", "cpp_grpc_library")

cpp_grpc_library(
    name = "simple_cc_grpc",
    deps = [":simple_proto"],
    visibility = ["//examples/hellogrpc/cc:__subpackages__"],
)

load("@build_stack_rules_proto//java:java_grpc_library.bzl", "java_grpc_library")

java_grpc_library(
    name = "simple_java_grpc",
    deps = [":simple_proto"],
    visibility = ["//examples/hellogrpc/java:__subpackages__"],
)

load("@build_stack_rules_proto//go:go_grpc_library.bzl", "go_grpc_library")

go_grpc_library(
    name = "simple_go_grpc",
    importpath = "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go",
    deps = [":simple_proto"],
    visibility = ["//examples/hellogrpc/go:__subpackages__"],
)

load("@build_stack_rules_proto//python:python_grpc_library.bzl", "python_grpc_library")

python_grpc_library(
    name = "simple_python_grpc",
    deps = [":simple_proto"],
    visibility = ["//examples/hellogrpc/py:__subpackages__"],
)
