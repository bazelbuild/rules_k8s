package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_protobuf//cpp:rules.bzl", "cc_proto_library")

cc_proto_library(
    name = "cc",
    protos = [
        "simple.proto",
    ],
)

load("@org_pubref_rules_protobuf//java:rules.bzl", "java_proto_library")

java_proto_library(
    name = "java",
    protos = [
        "simple.proto",
    ],
)

load("@org_pubref_rules_protobuf//go:rules.bzl", "go_proto_library")

go_proto_library(
    name = "go",
    importpath = "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go",
    protos = [
        "simple.proto",
    ],
)

load("@org_pubref_rules_protobuf//python:rules.bzl", "py_proto_library")

py_proto_library(
    name = "py",
    protos = [
        "simple.proto",
    ],
)
