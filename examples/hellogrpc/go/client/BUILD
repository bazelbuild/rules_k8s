package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_go//go:def.bzl", "go_binary")
load("@org_pubref_rules_protobuf//go:rules.bzl", "GRPC_COMPILE_DEPS")

go_binary(
    name = "client",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/rules_k8s/rules_k8s/examples/hellogrpc/go/client",
    deps = [
        "//examples/hellogrpc/proto:go",
    ] + GRPC_COMPILE_DEPS,
)
