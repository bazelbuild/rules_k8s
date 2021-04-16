ClusterProvider = provider(fields = ['name', 'cluster', 'image_chroot', 'context', 'kubeconfig', 'substitutions'])

def _cluster_impl(ctx):
    return ClusterProvider(
      name = ctx.attr.name,
      cluster = ctx.attr.cluster,
      image_chroot = ctx.attr.image_chroot,
      context = ctx.attr.context,
      kubeconfig = ctx.attr.kubeconfig,
      substitutions = ctx.attr.substitutions,
    )

cluster = rule(
    implementation = _cluster_impl,
    attrs = {
      "cluster": attr.string(),
      "image_chroot": attr.string(),
      "context": attr.string(),
      "kubeconfig": attr.label(
          allow_single_file = True,
      ),
      "substitutions": attr.string_dict(),
    }
)
