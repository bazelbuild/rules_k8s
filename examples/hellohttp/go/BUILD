package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_docker//docker/contrib/go:image.bzl", "go_image")

go_image(
    name = "server",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/rules_k8s/rules_k8s/examples/hellohttp/go",
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging",
    images = {
        "us.gcr.io/rules_k8s/hello-http:staging": ":server",
    },
    template = "//examples/hellohttp:deployment.yaml",
)
