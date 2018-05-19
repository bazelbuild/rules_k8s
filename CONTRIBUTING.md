# How to contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution,
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Tests

### Unit Tests

Unit tests can be run locally with minimal fuss.

**Requirements**

* [Node.js](https://nodejs.org/en/download/).

**Running Unit Tests**

```sh
bazel test //...
```

### End-to-end Tests

End-to-end tests require the provisioning of external services.

**Requirements**

* A container registry (e.g. [Google Container Registry](https://cloud.google.com/container-registry))
* A Kubernetes cluster (e.g. [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine))
* The host you are running tests from must match the architecture of the Kubernetes nodes (i.e. you cannot run tests on MacOS if your Kubernetes nodes run Linux)
* `kubectl` is configured with credentials for your Kubernetes cluster (e.g. `gcloud container clusters get-credentials ...`)
* A namespace exists for your `$USER` on the Kubernetes cluster (e.g. `kubectl create namespace $USER`)
* `docker` is configured for your container registry (e.g. `gcloud auth configure-docker`)

**Running Integration Tests**

Integration tests are declared in [CI configuration](.travis.yml).

Run a single integration test:

```sh
DOCKER_REPO_OVERRIDE=gcr.io/<your-gcp-project> \
BUILD_CLUSTER_OVERRIDE=<your-kubernetes-cluster> \
./examples/hellohttp/e2e-test.sh nodejs
```

Run all integration tests:

```sh
# The parens are significant. We only want to set the
# environment variables inside the subshell.
(export DOCKER_REPO_OVERRIDE=gcr.io/<your-gcp-project>;
export BUILD_CLUSTER_OVERRIDE=<your-kubernetes-cluster>;
grep e2e-test .travis.yml | sed '/^\s*#/ d' | sed 's/^[ -]*//' | \
while read -r TEST_CMD; do eval "$TEST_CMD"; done)
```

## Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult [GitHub Help] for more
information on using pull requests.

[GitHub Help]: https://help.github.com/articles/about-pull-requests/
