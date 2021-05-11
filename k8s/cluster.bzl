# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""An implementation of k8s_object for interacting with an object of kind."""
ClusterInfo = provider("Provides cluster information to k8s_object", fields = ["name", "cluster", "image_chroot", "context", "kubeconfig", "substitutions"])

def _cluster_impl(ctx):
    return ClusterInfo(
        name = ctx.attr.name,
        cluster = ctx.attr.cluster,
        image_chroot = ctx.attr.image_chroot,
        context = ctx.attr.context,
        kubeconfig = ctx.attr.kubeconfig,
        substitutions = ctx.attr.substitutions,
    )

k8s_cluster = rule(
    implementation = _cluster_impl,
    attrs = {
        "cluster": attr.string(),
        "context": attr.string(),
        "image_chroot": attr.string(),
        "kubeconfig": attr.label(
            allow_single_file = True,
        ),
        "substitutions": attr.string_dict(),
    },
)
