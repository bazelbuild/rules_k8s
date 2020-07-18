load("@io_bazel_rules_go//go:def.bzl", "go_binary")
load("@k8s_object//:defaults.bzl", "k8s_object")

k8s_object(
    name = "example",
    resolver = ":custom_resolver",
    template = "template.yaml",
)

go_binary(
    name = "custom_resolver",
    srcs = ["resolver.go"],
)
