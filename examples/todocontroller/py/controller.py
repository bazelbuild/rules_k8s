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

import json
from kubernetes import client, config, watch
import logging
import os

DOMAIN = "rules-k8s.bazel.io"

def main():
    config.load_incluster_config()

    # Exposed to us through the downward API.
    namespace = os.environ["MY_NAMESPACE"]

    crds = client.CustomObjectsApi()

    def mark_done(event, obj):
        metadata = obj.get("metadata")
        if not metadata:
            logging.error("No metadata in object, skipping: %s", json.dumps(obj, indent=1))
            return
        name = metadata.get("name")

        obj["spec"]["done"] = True
        obj["spec"]["comment"] = "DEMO "

        logging.error("Updating: %s", name)
        crds.replace_namespaced_custom_object(DOMAIN, "v1", namespace, "todos", name, obj)

    resource_version = ''
    while True:
        stream = watch.Watch().stream(crds.list_namespaced_custom_object,
                                      DOMAIN, "v1", namespace, "todos",
                                      resource_version=resource_version)
        for event in stream:
            obj = event["object"]

            spec = obj.get("spec")
            if not spec:
                logging.error("No 'spec' in object, skipping event: %s", json.dumps(obj, indent=1))
            else:
                if not spec.get("done", True):
                    mark_done(event, obj)

            # Configure where to resume streaming.
            metadata = obj.get("metadata")
            if metadata:
                resource_version = metadata["resourceVersion"]

if __name__ == "__main__":
    main()
