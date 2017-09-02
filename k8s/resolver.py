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
"""Walks a yaml object and resolves all docker_name.Tag to docker_name.Digest.
"""

import argparse
import sys

from containerregistry.client import docker_creds
from containerregistry.client import docker_name
from containerregistry.client.v2_2 import docker_image as v2_2_image
from containerregistry.tools import patched
from containerregistry.transport import transport_pool

import httplib2
import yaml


parser = argparse.ArgumentParser(
    description='Resolve image references to digests.')

parser.add_argument(
  '--template', action='store',
  help='The template file to resolve.')


def Resolve(input, tag_to_digest):
  """Translate tag references within the input yaml into digests."""
  def walk_dict(d):
    return {
      walk(k): walk(v)
      for (k, v) in d.iteritems()
    }

  def walk_list(l):
    return [walk(e) for e in l]

  def walk_string(s):
    try:
      as_tag = docker_name.Tag(s)
      digest = tag_to_digest(as_tag)
      return digest
    except:
      return s

  def walk(o):
    if isinstance(o, dict):
      return walk_dict(o)
    if isinstance(o, list):
      return walk_list(o)
    if isinstance(o, str):
      return walk_string(o)
    return o

  return yaml.dump(walk(yaml.load(input)))


def TagToDigest(tag, overrides, transport):
  """Turn a docker_name.Tag into a stringified digest."""
  if tag in overrides:
    return str(overrides[tag])

  def fully_qualify_digest(digest):
    return str(docker_name.Digest('{registry}/{repo}@{digest}'.format(
      registry=tag.registry, repo=tag.repository, digest=digest)))

  # Resolve the tag to digest using the standard
  # Docker keychain logic.
  creds = docker_creds.DefaultKeychain.Resolve(tag)
  with v2_2_image.FromRegistry(tag, creds, transport) as img:
    if img.exists():
      digest = fully_qualify_digest(img.digest())
      overrides[tag] = digest
      return digest

  # If the tag doesn't exists as v2.2, then try as v2.
  with v2_image.FromRegistry(tag, creds, transport) as img:
    digest = fully_qualify_digest(img.digest())
    overrides[tag] = digest
    return digest


_THREADS = 32
_DOCUMENT_DELIMITER = '---\n'


def main():
  args = parser.parse_args()

  transport = transport_pool.Http(httplib2.Http, size=_THREADS)

  overrides = {}
  # TODO(mattmoor): Support publishing images and using the
  # published digest to override resolution (to avoid races).

  with open(args.template, 'r') as f:
    inputs = f.read()

  print(_DOCUMENT_DELIMITER.join([
    Resolve(x, lambda t: TagToDigest(t, overrides, transport))
    for x in inputs.split(_DOCUMENT_DELIMITER)
  ]))


if __name__ == '__main__':
  with patched.Httplib2():
    main()
