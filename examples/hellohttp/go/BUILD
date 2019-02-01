load("@io_bazel_rules_docker//go:image.bzl", "go_image")
load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

package(default_visibility = ["//visibility:public"])

go_image(
    name = "server",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/not-my-project/examples/hellohttp/go",
)

k8s_deploy(
    name = "staging",
    images = {
        "hello-http-image:latest": ":server",
    },
    template = "//examples/hellohttp:deployment.yaml",
)
