ClusterFlagProvider = provider(fields = ['cluster'])

def _cluster_flag_impl(ctx):
    # use `ctx.build_setting_value` to access the raw value
    # of this build setting. This value is either derived from
    # the default value set on the target or from the setting
    # being set somewhere on the command line/in a transition, etc.
    raw_cluster = ctx.build_setting_value

    # Returns a provider like a normal rule
    return ClusterFlagProvider(cluster = raw_cluster)

cluster_flag = rule(
    implementation = _cluster_flag_impl,
    # This line separates a build setting from a regular target, by using
    # the `build_setting` atttribute, you mark this rule as a build setting
    # including what raw type it is and if it can be used on the command
    # line or not (if yes, you must set `flag = True`)
    build_setting = config.string(flag = True)
)

NamespaceFlagProvider = provider(fields = ['namespace'])

def _namespace_flag_impl(ctx):
    # use `ctx.build_setting_value` to access the raw value
    # of this build setting. This value is either derived from
    # the default value set on the target or from the setting
    # being set somewhere on the command line/in a transition, etc.
    raw_namespace = ctx.build_setting_value

    # Returns a provider like a normal rule
    return NamespaceFlagProvider(namespace = raw_namespace)

namespace_flag = rule(
    implementation = _namespace_flag_impl,
    # This line separates a build setting from a regular target, by using
    # the `build_setting` atttribute, you mark this rule as a build setting
    # including what raw type it is and if it can be used on the command
    # line or not (if yes, you must set `flag = True`)
    build_setting = config.string(flag = True)
)
