package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_docker//docker/contrib/go:image.bzl", "go_image")
load("@org_pubref_rules_protobuf//go:rules.bzl", "GRPC_COMPILE_DEPS")

go_image(
    name = "server",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/rules_k8s/rules_k8s/examples/hellogrpc/go/server",
    deps = [
        "//examples/hellogrpc/proto:go",
    ] + GRPC_COMPILE_DEPS,
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging",
    images = {
        "us.gcr.io/rules_k8s/hello-grpc:staging": ":server",
    },
    template = "//examples/hellogrpc:deployment.yaml",
)
