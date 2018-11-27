# Bazel Kubernetes Rules

Prow | Bazel CI
:---: | :---:
[![Build status](https://prow.k8s.io/badge.svg?jobs=pull-rules-k8s-*)](https://prow.k8s.io/?repo=bazelbuild%2Frules_k8s) | [![Build status](https://badge.buildkite.com/4eafd3b619b9febae679bac4ce75b6b74643d48384e7f36eeb.svg)](https://buildkite.com/bazel/k8s-rules-k8s-postsubmit)

## Rules

* [k8s_defaults](#k8s_defaults)
* [k8s_object](#k8s_object)
* [k8s_objects](#k8s_objects)

## Overview

This repository contains rules for interacting with Kubernetes
configurations / clusters.

## Setup

Add the following to your `WORKSPACE` file to add the necessary external dependencies:

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "io_bazel_rules_docker",
    commit = "{HEAD}",
    remote = "https://github.com/bazelbuild/rules_docker.git",
)

load(
  "@io_bazel_rules_docker//container:container.bzl",
  container_repositories = "repositories",
)

container_repositories()

# This requires rules_docker to be fully instantiated before
# it is pulled in.
git_repository(
    name = "io_bazel_rules_k8s",
    commit = "{HEAD}",
    remote = "https://github.com/bazelbuild/rules_k8s.git",
)

load("@io_bazel_rules_k8s//k8s:k8s.bzl", "k8s_repositories")

k8s_repositories()
```

## Kubernetes Authentication

As is somewhat standard for Bazel, the expectation is that the
`kubectl` toolchain is preconfigured to authenticate with any clusters
you might interact with.

For more information on how to configure `kubectl` authentication, see the
Kubernetes [documentation](https://kubernetes.io/docs/admin/authentication/).

*NOTE: we are currently experimenting with toolchain features in these rules
so there will be changes upcoming to how this configuration is performed*

### Container Engine Authentication

For Google Container Engine (GKE), the `gcloud` CLI provides a [simple
command](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)
for setting up authentication:
```shell
gcloud container clusters get-credentials <CLUSTER NAME>
```

*NOTE: we are currently experimenting with toolchain features in these rules
so there will be changes upcoming to how this configuration is performed*

## Dependencies

*New: Starting https://github.com/bazelbuild/rules_k8s/commit/ff2cbf09ae1f0a9c7ebdfc1fa337044158a7f57b*

These rules can either use a pre-installed `kubectl` tool (default) or
build the `kubectl` tool from sources.

The `kubectl` tool is used when executing the `run` action from bazel.

The `kubectl` tool is configured via a toolchain rule. Read more about
the kubectl toolchain [here](toolchains/kubectl#kubectl-toolchain).

If GKE is used, also the `gcloud` sdk needs to be installed.

*NOTE: we are currently experimenting with toolchain features in these rules
so there will be changes upcoming to how this configuration is performed*

## Examples

### Basic "deployment" objects

```python
load("@io_bazel_rules_k8s//k8s:object.bzl", "k8s_object")

k8s_object(
  name = "dev",
  kind = "deployment",

  # A template of a Kubernetes Deployment object yaml.
  template = ":deployment.yaml",

  # An optional collection of docker_build images to publish
  # when this target is bazel run.  The digest of the published
  # image is substituted as a part of the resolution process.
  images = {
    "gcr.io/rules_k8s/server:dev": "//server:image"
  },
)
```

### Aliasing (e.g. `k8s_deploy`)

In your `WORKSPACE` you can set up aliases for a more readable short-hand:
```python
load("@io_bazel_rules_k8s//k8s:k8s.bzl", "k8s_defaults")

k8s_defaults(
  # This becomes the name of the @repository and the rule
  # you will import in your BUILD files.
  name = "k8s_deploy",
  kind = "deployment",
  # This is the name of the cluster as it appears in:
  #   kubectl config view --minify -o=jsonpath='{.contexts[0].context.cluster}'
  cluster = "my-gke-cluster",
)
```

Then in place of the above, you can use the following in your `BUILD` file:

```python
load("@k8s_deploy//:defaults.bzl", "k8s_deploy")

k8s_deploy(
  name = "dev",
  template = ":deployment.yaml",
  images = {
    "gcr.io/rules_k8s/server:dev": "//server:image"
  },
)
```

Note that in `load("@k8s_deploy//:defaults.bzl", "k8s_deploy")` both `k8s_deploy`'s are references to the `name` parameter passed to `k8s_defaults`. If you change `name = "k8s_deploy"` to something else, you will need to change the `load` statement in both places.

### Multi-Object Actions

It is common practice in the Kubernetes world to have multiple objects that
comprise an application.  There are two main ways that we support interacting
with these kinds of objects.

The first is to simply use a template file that contains your N objects
delimited with `---`, and omitting `kind="..."`.

The second is through the use of `k8s_objects`, which aggregates N `k8s_object`
rules:
```python
# Note the plurality of "objects" here.
load("@io_bazel_rules_k8s//k8s:objects.bzl", "k8s_objects")

k8s_objects(
   name = "deployments",
   objects = [
      ":foo-deployment",
      ":bar-deployment",
      ":baz-deployment",
   ]
)

k8s_objects(
   name = "services",
   objects = [
      ":foo-service",
      ":bar-service",
      ":baz-service",
   ]
)

# These rules can be nested
k8s_objects(
   name = "everything",
   objects = [
      ":deployments",
      ":services",
      ":configmaps",
      ":ingress",
   ]
)
```

This can be useful when you want to be able to stand up a full environment,
which includes resources that are expensive to recreate (e.g. LoadBalancer),
but still want to be able to quickly iterate on parts of your application.


### Developer Environments

A common practice to avoid clobbering other users is to do your development
against an isolated environment.  Two practices are fairly common-place.
1. Individual development clusters
1. Development "namespaces"

To support these scenarios, the rules support using "stamping" variables to
customize these arguments to `k8s_defaults` or `k8s_object`.

For per-developer clusters, you might use:
```python
k8s_defaults(
  name = "k8s_dev_deploy",
  kind = "deployment",
  cluster = "gke_dev-proj_us-central5-z_{BUILD_USER}",
)
```

For per-developer namespaces, you might use:
```python
k8s_defaults(
  name = "k8s_dev_deploy",
  kind = "deployment",
  cluster = "shared-cluster",
  namespace = "{BUILD_USER}",
)
```

You can customize the stamp variables that are available at a repository level
by leveraging `--workspace_status_command`.  One pattern for this is to check in
the following:
```shell
$ cat .bazelrc
build --workspace_status_command=./print-workspace-status.sh

$ cat print-workspace-status.sh
cat <<EOF
VAR1 value1
# This can be overriden by users if they "export VAR2_OVERRIDE"
VAR2 ${VAR2_OVERRIDE:-default-value2}
EOF
```

For more information on "stamping", you can see also the `rules_docker`
documentation on stamping [here](
https://github.com/bazelbuild/rules_docker#stamping).


#### Don't tread on my tags

Another ugly problem remains, which is that image references are still
shared across developers, and while our resolution to digests avoids races, we
may not want them trampling on the same tag, or on production tags if shared
templates are being used.

Moreover, developers may not have access to push to the images referenced in a
particular template, or the development cluster to which they are deploying may
not be able to pull them (e.g. clusters in different GCP projects).

To resolve this, we enable developers to "chroot" the image references,
publishing them instead to that reference under another repository.

Consider the following, where developers use GCP projects named
`company-{BUILD_USER}`:
```python
k8s_defaults(
  name = "k8s_dev_deploy",
  kind = "deployment",
  cluster = "gke_company-{BUILD_USER}_us-central5-z_da-cluster",
  image_chroot = "us.gcr.io/company-{BUILD_USER}/dev",
)
```
In this example, the `k8s_dev_deploy` rules will target the developer's cluster
in their project, and images will all be published under the `image_chroot`.

For example, if the BUILD file contains:
```python
k8s_deploy(
  name = "dev",
  template = ":deployment.yaml",
  images = {
    "gcr.io/rules_k8s/server:dev": "//server:image"
  },
)
```

Then the references to `gcr.io/rules_k8s/server:dev` will be replaced with one
to: `us.gcr.io/company-{BUILD_USER}/dev/gcr.io/rules_k8s/server@sha256:...`.


### Custom resolvers

Sometimes, you need to replace additional runtime parameters in the YAML file.
While you can use `expand_template` for parameters known to the build system,
you'll need a custom resolver if the parameter is determined at deploy time.
A common example is Google Cloud Endpoints service versions, which are
determined by the server.

You can pass a custom resolver executable as the `resolver` argument of all
rules:

```python
sh_binary(
  name = "my_script",
  ...
)

k8s_deploy(
  name = "dev"
  template = ":deployment.yaml",
  images = {
    "gcr.io/rules_k8s/server:dev": "//server:image"
  },
  resolver = "//my_script",
)
```

This script may need to invoke the default resolver (`//k8s:resolver`) with all
its arguments. It may capture the default resolver's output and apply additional
modifications to the YAML.


## Usage

The `k8s_object[s]` rules expose a collection of actions.  We will follow the `:dev`
target from the example above.

### Build

Build builds all of the constituent elements, and makes the template available
as `{name}.yaml`.  If `template` is a generated input, it will be built.
Likewise, any `docker_build` images referenced from the `images={}` attribute
will be built.

```shell
bazel build :dev
```

### Resolve

Deploying with tags, especially in production, is a bad practice because they
are mutable.  If a tag changes, it can lead to inconsistent versions of your app
running after auto-scaling or auto-healing events.  Thankfully in v2 of the
Docker Registry, digests were introduced.  Deploying by digest provides
cryptographic guarantees of consistency across the replicas of a deployment.

You can "resolve" your resource `template` by running:

```shell
bazel run :dev
```

The resolved `template` will be printed to `STDOUT`.

This command will publish any `images = {}` present in your rule, substituting
those exact digests into the yaml template, and for other images resolving the
tags to digests by reaching out to the appropriate registry.  Any images that
cannot be found or accessed are left unresolved.

**This process only supports fully-qualified tag names.**  This means you must
always specify tag and registry domain names (no implicit `:latest`).


### Create

Users can create an environment by running:
```shell
bazel run :dev.create
```

This deploys the **resolved** template, which includes publishing images.

### Update

Users can update (replace) their environment by running:
```shell
bazel run :dev.replace
```

Like `.create` this deploys the **resolved** template, which includes
republishing images.  **This action is intended to be the workhorse
of fast-iteration development** (rebuilding / republishing / redeploying).

### Apply

Users can "apply" a configuration by running:
```shell
bazel run :dev.apply
```

`:dev.apply` maps to `kubectl apply`, which will create or replace an existing
configuration.  For more information see the `kubectl` documentation.

This applies the **resolved** template, which includes republishing images.
**This action is intended to be the workhorse of fast-iteration development**
(rebuilding / republishing / redeploying).

### Delete

Users can tear down their environment by running:
```shell
bazel run :dev.delete
```

It is notable that despite deleting the deployment, this will NOT delete
any services currently load balancing over the deployment; this is intentional
as creating load balancers can be slow.

### Describe (`k8s_object`-only)

Users can "describe" their environment by running:

```shell
bazel run :dev.describe
```

<a name="k8s_object"></a>
## k8s_object

```python
k8s_object(name, kind, template)
```

A rule for interacting with Kubernetes objects.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>Unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>kind</code></td>
      <td>
        <p><code>Kind, required</code></p>
        <p>The kind of the Kubernetes object in the yaml.</p>
        <p><b>If this is omitted, the <code>create, replace, delete,
          describe</code> actions will not exist.</b></p>
      </td>
    </tr>
    <tr>
      <td><code>cluster</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The name of the cluster to which <code>create, replace, delete,
          describe</code> should speak. Subject to "Make" variable substitution.</p>
        <p><b>If this is omitted, the <code>create, replace, delete,
          describe</code> actions will not exist.</b></p>
      </td>
    </tr>
    <tr>
      <td><code>context</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The name of a kubeconfig context to use. Subject to "Make" variable 
          substitution.</p>
        <p><b>If this is omitted, the current context will be used.</b></p>
      </td>
    </tr>    
    <tr>
      <td><code>namespace</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The namespace on the cluster within which the actions are
          performed. Subject to "Make" variable substitution.</p>
        <p><b>If this is omitted, it will default to the value specified
          in the template or if also unspecified there, to the value
          <code>"default"</code>.</b></p>
      </td>
    </tr>
    <tr>
      <td><code>user</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The user to authenticate to the cluster as configured with kubectl.
          Subject to "Make" variable substitution.</p>
        <p><b>If this is omitted, kubectl will authenticate as the user from the 
          current context.</b></p>
      </td>
    </tr>
    <tr>
      <td><code>template</code></td>
      <td>
        <p><code>yaml or json file; required</code></p>
        <p>The yaml or json for a Kubernetes object.</p>
      </td>
    </tr>
    <tr>
      <td><code>images</code></td>
      <td>
        <p><code>string to label dictionary; required</code></p>
        <p>When this target is <code>bazel run</code> the images
          referenced by label will be published to the tag key.</p>
       <p>The published digests of these images will be substituted
          directly, so as to avoid a race in the resolution process</p>
      </td>
    </tr>
    <tr>
      <td><code>image_chroot</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The repository under which to actually publish Docker images.</p>
      </td>
    </tr>
    <tr>
      <td><code>resolver</code></td>
      <td>
        <p><code>target, optional</code></p>
        <p>A build target for the binary that's called to resolves references
           inside the Kubernetes YAML files.</p>
      </td>
    </tr>
    <tr>
      <td><code>args</code></td>
      <td>
        <p><code>string_list, optional</code></p>
        <p>Additional arguments to pass to the kubectl command at execution.</p>
        <p>NOTE: You can also pass args via the cli by run something like:
	      <code>bazel run some_target -- some_args</code></p>
        <p>NOTE: Not all options are available for all kubectl commands. To view the list of global options run: <code>kubectl options</code></p>
      </td>
    </tr>
  </tbody>
</table>


<a name="k8s_objects"></a>
## k8s_objects

```python
k8s_objects(name, objects)
```

A rule for interacting with multiple Kubernetes objects.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>Unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>objects</code></td>
      <td>
        <p><code>Label list; required</code></p>
        <p>The list of objects on which actions are taken.</p>
	<p>When <code>bazel run</code> this target resolves each of the object
	   targets which includes publishing their associated images, and will
	   print a <code>---</code> delimited yaml.</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="k8s_defaults"></a>
## k8s_defaults

```python
k8s_defaults(name, kind)
```

A repository rule that allows users to alias `k8s_object` with default values.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>The name of the repository that this rule will create.</p>
        <p>Also the name of rule imported from
          <code>@name//:defaults.bzl</code></p>
      </td>
    </tr>
    <tr>
      <td><code>kind</code></td>
      <td>
        <p><code>Kind, optional</code></p>
        <p>The kind of objects the alias of <code>k8s_object</code> handles.</p>
      </td>
    </tr>
    <tr>
      <td><code>cluster</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The name of the cluster to which <code>create, replace, delete,
           describe</code> should speak.</p>
	<p>This should match the cluster name as it would appear in
           <code>kubectl config view --minify -o=jsonpath='{.contexts[0].context.cluster}'</code></p>
      </td>
    </tr>
    <tr>
      <td><code>context</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The name of a kubeconfig context to use.</p>
      </td>
    </tr>
    <tr>
      <td><code>namespace</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The namespace on the cluster within which the actions are
           performed.</p>
      </td>
    </tr>
    <tr>
      <td><code>user</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The user to authenticate to the cluster as configured with kubectl.</p>
      </td>
    </tr>
    <tr>
      <td><code>image_chroot</code></td>
      <td>
        <p><code>string, optional</code></p>
        <p>The repository under which to actually publish Docker images.</p>
      </td>
    </tr>
    <tr>
      <td><code>resolver</code></td>
      <td>
        <p><code>target, optional</code></p>
        <p>A build target for the binary that's called to resolves references
           inside the Kubernetes YAML files.</p>
      </td>
    </tr>
  </tbody>
</table>


## Support

Users find on stackoverflow, slack and Google Group mailing list.

### Stackoverflow

Stackoverflow is a great place for developers to help each other.

Search through [existing questions] to see if someone else has had the same issue as you.

If you have a new question, please [ask] the stackoverflow community. Include `rules_k8s` in the title and add `[bazel]` and `[kubernetes]` tags.

### Google group mailing list

The general [bazel support] options links to the official [bazel-discuss] Google group mailing list.


### Slack and IRC

Slack and IRC are great places for developers to chat with each other.

There is a `#bazel` channel in the kubernetes slack. Visit the [kubernetes community] page to find the [slack.k8s.io] invitation link.

There is also a `#bazel` channel on [Freenode IRC], although we have found the slack channel more engaging.


[Freenode IRC]: https://freenode.net/
[bazel support]: https://bazel.build/support.html
[bazel-discuss]: https://groups.google.com/forum/#!forum/bazel-discuss
[existing questions]: https://stackoverflow.com/search?q=rules_k8s
[kubernetes community]: https://kubernetes.io/community/
[slack.k8s.io]: http://slack.k8s.io/
