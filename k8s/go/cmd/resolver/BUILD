load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["resolver.go"],
    importpath = "github.com/bazelbuild/rules_k8s/k8s/go/cmd/resolver",
    visibility = ["//visibility:private"],
    deps = [
        "@io_bazel_rules_docker//container/go/pkg/compat:go_default_library",
        "@io_bazel_rules_docker//container/go/pkg/utils:go_default_library",
    ],
)

go_binary(
    name = "resolver",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
