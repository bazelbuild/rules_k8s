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

import io
import os
import sys
import unittest

import mock
from containerregistry.client import docker_name
from containerregistry.client.v2 import docker_image as v2_image
from containerregistry.client.v2_2 import docker_image as v2_2_image

from k8s import resolver

_BAD_TRANSPORT = None


def TestData(name):
  return os.path.join(os.environ['TEST_SRCDIR'], name)


class ResolverTest(unittest.TestCase):

  def test_complex_walk(self):
    present = 'gcr.io/foo/bar:baz'
    not_present = 'gcr.io/foo/bar:blah'
    expected = 'foo@sha256:deadbeef'
    unexpected = 'bar@sha256:baadf00d'
    values = {
      docker_name.Tag(present): expected,
      docker_name.Tag(not_present): unexpected,
    }
    input = """
key1:
  key2:
  - value1
  - {present}
""".format(present=present)
    output = resolver.Resolve(input, lambda x: values[x])

    self.assertTrue(expected in output)
    self.assertFalse(unexpected in output)

  def test_tag_to_digest_cached(self):
    tag = docker_name.Tag('gcr.io/foo/bar:baz')
    expected_digest = 'gcr.io/foo/bar@sha256:deadbeef'
    actual_digest = resolver.TagToDigest(tag, {
      tag: expected_digest,
    }, _BAD_TRANSPORT)
    self.assertEqual(actual_digest, expected_digest)

  def test_tag_to_digest_not_cached(self):
    with v2_2_image.FromTarball(TestData(
        'io_bazel_rules_k8s/examples/hello-grpc/cc/server/server.tar')) as img:
      # Add a fake exists method to look like FromRegistry
      img.exists = lambda: True
      with mock.patch.object(v2_2_image, 'FromRegistry',
                             return_value=img):
        tag = docker_name.Tag('gcr.io/foo/bar:baz')
        expected_digest = docker_name.Digest('gcr.io/foo/bar@' + img.digest())
        actual_digest = resolver.TagToDigest(tag, {}, _BAD_TRANSPORT)
        self.assertEqual(actual_digest, str(expected_digest))


if __name__ == '__main__':
  unittest.main()
