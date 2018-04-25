package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_docker//go:image.bzl", "go_image")

go_image(
    name = "server",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/not-my-project/examples/hellohttp/go",
)

load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
    name = "staging-deployment",
    images = {
        "hello-http-image": ":server",
    },
    template = "//examples/hellohttp:deployment.yaml",
)

load("@k8s_service//:defaults.bzl", "k8s_service")

k8s_service(
    name = "staging-service",
    template = "//examples/hellohttp:service.yaml",
)

load("@io_bazel_rules_k8s//k8s:objects.bzl", "k8s_objects")

k8s_objects(
    name = "staging",
    objects = [
        ":staging-deployment",
        ":staging-service",
    ],
)
