package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_go//go:def.bzl", "go_binary")

go_binary(
    name = "client_bin",
    srcs = ["main.go"],
    importpath = "github.com/bazelbuild/rules_k8s/rules_k8s/examples/hellogrpc/go/client",
    deps = [
        "//examples/hellogrpc/proto:simple_go_grpc",
        "@org_golang_google_grpc//:go_default_library",
    ],
)

# Normalize the binary name per
# https://github.com/bazelbuild/rules_go/issues/1239#issuecomment-361296415
genrule(
    name = "client_exe",
    srcs = [":client_bin"],
    outs = ["client"],
    cmd = "cp $(SRCS) $@",
    output_to_bindir = True,
)

