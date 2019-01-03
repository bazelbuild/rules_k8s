# Running rules_k8s e2e tests locally

Currently the rules_k8s e2e tests can only be run in a Linux environment. To be
able to run the tests locally, it's required to set up minikube and docker.
Minikube is a tool that enables running Kubernetes locally and docker allows to
set up a local registry.

## Installation and Setup

### Prerequisites

The main requirement to run the e2e tests is to use Linux. But for an easier
setup, it's recommended to use an identical VM to the one for which this setup
was tested.

If you are interested in using the same type of VM, then follow these
[instructions](https://cloud.google.com/compute/docs/quickstart-linux) to
create a Linux VM in the Google Compute Engine (GCE). Select the "Boot disk"
to be of type "Google Drawfork Ubuntu 16.04 LTS" with at least 30GB of
storage. Also switch to the root user to avoid setting all the required
permissions that will be required in the next steps.

If you decide to use any other Linux machine, then first install the Google
Cloud SDK as described [here](https://cloud.google.com/sdk/docs/quickstart-linux).

### Installing

1. Install [Bazel](https://docs.bazel.build/versions/master/install.html).
2. Install [docker](https://docs.docker.com/install/). This must be a version
supported by minikube and is not necessarily the latest available version. The
latest supported docker version by minikube can be found in the
[Minikube Release Notes](https://github.com/kubernetes/minikube/blob/master/CHANGELOG.md).
    1. [Run a local registry](https://docs.docker.com/registry/deploying/#run-a-local-registry).
    2. Confirm that the local registry works properly by following these
    [steps](https://docs.docker.com/registry/deploying/#copy-an-image-from-docker-hub-to-your-registry).
    3. Make a note of the name of your local registry. If followed the setup
    steps exactly as described, then this should be `localhost:5000`
3. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
4. Install [minikube](https://github.com/kubernetes/minikube/releases).
    1. [Run Kubernetes locally via minikube](https://kubernetes.io/docs/setup/minikube/)
    with the following command:
    ```bash
    minikube start --vm-driver=none
    ```
    2. You can confirm that Kubernetes is running locally with
    ```bash
    minikube status
    ```
5. Clone the [rules_k8s](https://github.com/bazelbuild/rules_k8s) repo and make
the following code changes in the WORKSPACE file:
    1. Change the value of the `_CLUSTER` variable to
    ```python
    _CLUSTER = “minikube”
    ```
    2. Change the value of the `image_chroot` attribute in the `k8s_object` and
    `k8s_deploy` targets to start with the name of your local registry from step 2(iii)
    ```python
    image_chroot = “localhost:5000/rules_k8s”
    ```

### Running Tests

From the project's root directory, run the test script
```bash
./test-e2e-local.sh
```

## Caveats

* When tests run locally they create (and when finished, delete) a namespace
called `build-0`. So be cautious when naming new namespaces inside the same
local Kubernetes cluster used for local testing.
* After running the e2e tests locally, it's expected that a few changes will be
made to some files inside the project. This has no harm unless you decide to
re-run the tests. Please undo the local changes created by the e2e tests run if
you plan on re-running the tests.
* Running the e2e tests locally will consume a substantial amount of storage
(&sim;20GB), so make sure you have enough space before running these tests.

Apologies for any inconveniences these caveats or prerequisites may cause you.
