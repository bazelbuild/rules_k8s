ClustersProvider = provider(fields = ['clusters'])

def _clusters_impl(ctx):
    return ClustersProvider(clusters = ctx.attr.clusters)

k8s_clusters = rule(
    implementation = _clusters_impl,
    attrs = {
      "clusters": attr.label_list(),
    }
)
