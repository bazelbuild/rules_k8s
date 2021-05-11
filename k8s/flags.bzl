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
ClusterFlagInfo = provider("Provides the value of the cluster flag passed on command line", fields = ["cluster"])

def _cluster_flag_impl(ctx):
    # use `ctx.build_setting_value` to access the raw value
    # of this build setting. This value is either derived from
    # the default value set on the target or from the setting
    # being set somewhere on the command line/in a transition, etc.
    raw_cluster = ctx.build_setting_value

    # Returns a provider like a normal rule
    return ClusterFlagInfo(cluster = raw_cluster)

cluster_flag = rule(
    implementation = _cluster_flag_impl,
    # This line separates a build setting from a regular target, by using
    # the `build_setting` atttribute, you mark this rule as a build setting
    # including what raw type it is and if it can be used on the command
    # line or not (if yes, you must set `flag = True`)
    build_setting = config.string(flag = True),
)
