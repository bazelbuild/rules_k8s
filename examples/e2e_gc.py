"""
Queries the Kuebernetes namespaces created by rules_k8s E2E tests and attempts
to delete them. Deletion is best effort, i.e., any errors returned by
any kubectl calls are ignored.
"""

import subprocess
import logging
import json
from datetime import datetime

# Logger instance
_log = None

def list_namespaces():
    """
    Returns a list of strings of namespace names that were created by the e2e
    tests in rules_k8s and are older than an hour.
    """
    result = []
    ofp = open("namespaces.json", "w")
    p = subprocess.Popen(["kubectl", "get", "namespaces", "-o", "json"],
        stdout=ofp)
    retcode = p.wait()
    if retcode != 0:
        _log.error("Got non zero result {} when trying to ".format(retcode) +\
            "list kubernetes namespaces. Returning success anyway as this" +\
            " script is best effort")
        return result
    ofp.close()
    utcnow = datetime.utcnow()
    with open("namespaces.json") as ifp:
        json_doc = json.load(ifp)
        namespaces = json_doc["items"]
        for n in namespaces:
            name = n["metadata"]["name"]
            created = n["metadata"]["creationTimestamp"]
            created = datetime.strptime(created, "%Y-%m-%dT%H:%M:%SZ")
            timedelta = utcnow - created
            _log.info("Found namespace: {}, created: {}, age: {}s".format(name,
                created, timedelta.total_seconds()))
            if not name.startswith("build-"):
                # Not created by an e2e test run.
                _log.info(
                    "Skipping {} as name doesn't begin with 'build-'.".format(
                    name
                ))
                continue
            if timedelta.total_seconds() < 3600:
                _log.info(
                    "Skipping {} as age of namespace is less than 1hr.".format(
                    name
                ))
                continue
            _log.info("Nominating namespace {} for garbage collection.".format(
                name
            ))
            result.append(name)
        _log.info("{}/{} namespaces nominated for garbage collection.".format(
            len(result), len(namespaces)
        ))
    return result

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    _log = logging.getLogger("e2e_gc")
    _log.info(
        "Running the rules_k8s E2E Testing GKE Garbage Collection Utility.")
    namespaces = list_namespaces()
    for n in namespaces:
        _log.info("Attempting to delete namespace: {}".format(n))
        p = subprocess.Popen(["kubectl", "delete", "namespaces/{}".format(n)])
        r = p.wait()
        if r != 0:
            _log.warn("Namespace deletion for {} returned non zero status"+\
                " status code: {}".format(r))
        else:
            _log.info("Deleted namespace: {}".format(n))
    _log.info("rules_k8s E2E Testing GKE Garbage Collection Utility is done.")
