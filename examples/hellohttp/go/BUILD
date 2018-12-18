package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_docker//go:image.bzl", "go_image")

go_image(
    name = "server",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/not-my-project/examples/hellohttp/go",
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging",
    images = {
        "hello-http-image:latest": ":server",
    },
    template = "//examples/hellohttp:deployment.yaml",
)
