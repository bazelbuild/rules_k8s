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
import shutil
import sys
import tempfile
import unittest

import mock
from containerregistry.client import docker_name
from containerregistry.client.v2_2 import docker_image as v2_2_image
from containerregistry.client.v2_2 import docker_session as v2_2_session
from containerregistry.client.v2_2 import save

from k8s import resolver

_BAD_TRANSPORT = None


def TestData(name):
  return os.path.join(os.environ['TEST_SRCDIR'], name)


class NopPush(object):

  def upload(self, unused_image):
    pass

  def __enter__(self):
    return self

  def __exit__(self, unused_type, unused_value, unused_traceback):
    return


class ResolverTest(unittest.TestCase):

  def setUp(self):
    self._tmpdir = tempfile.mkdtemp()

  def tearDown(self):
    shutil.rmtree(self._tmpdir)

  def test_complex_walk(self):
    present = 'gcr.io/foo/bar:baz'
    not_present = 'gcr.io/foo/bar:blah'
    expected = 'foo@sha256:deadbeef'
    unexpected = 'bar@sha256:baadf00d'
    values = {
      present: expected,
      not_present: unexpected,
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
    tag_as_string = 'gcr.io/foo/bar:baz'
    expected_digest = 'gcr.io/foo/bar@sha256:deadbeef'
    actual_digest = resolver.StringToDigest(tag_as_string, {
      tag_as_string: expected_digest,
    }, _BAD_TRANSPORT)
    self.assertEqual(actual_digest, expected_digest)

  def test_tag_to_digest_sentinel(self):
    sentinel_string = 'XXXXX'
    expected_digest = 'gcr.io/foo/bar@sha256:deadbeef'
    actual_digest = resolver.StringToDigest(sentinel_string, {
      sentinel_string: expected_digest,
    }, _BAD_TRANSPORT)
    self.assertEqual(actual_digest, expected_digest)

  def test_tag_to_digest_not_cached(self):
    with v2_2_image.FromTarball(TestData(
        'io_bazel_rules_k8s/examples/hellogrpc/cc/server/server.tar')) as img:
      # Add a fake exists method to look like FromRegistry
      img.exists = lambda: True
      with mock.patch.object(v2_2_image, 'FromRegistry',
                             return_value=img):
        tag_as_string = 'gcr.io/foo/bar:baz'
        expected_digest = docker_name.Digest('gcr.io/foo/bar@' + img.digest())
        actual_digest = resolver.StringToDigest(
          tag_as_string, {}, _BAD_TRANSPORT)
        self.assertEqual(actual_digest, str(expected_digest))

  def test_publish_legacy(self):
    td = TestData(
        'io_bazel_rules_k8s/examples/hellogrpc/cc/server/server.tar')
    name = docker_name.Tag('fake.gcr.io/foo/bar:baz')

    with mock.patch.object(v2_2_session, 'Push', return_value=NopPush()):
      (tag, published_tag, digest) = resolver.Publish(
          _BAD_TRANSPORT, None, name=str(name), tarball=td)
      self.assertEqual(tag, str(name))
      self.assertEqual(published_tag, str(name))
      with v2_2_image.FromTarball(td) as img:
        self.assertEqual(digest.digest, img.digest())

  def test_publish_fast(self):
    td = TestData(
        'io_bazel_rules_k8s/examples/hellogrpc/cc/server/server.tar')
    name = docker_name.Tag('fake.gcr.io/foo/bar:baz')

    with v2_2_image.FromTarball(td) as img:
      (config_path, layer_data) = save.fast(img, self._tmpdir, threads=16)
      expected_digest = img.digest()

    with mock.patch.object(v2_2_session, 'Push', return_value=NopPush()):
      (tag, published_tag, digest) = resolver.Publish(
          _BAD_TRANSPORT, None, name=str(name), config=config_path,
          digest=','.join([h for (h, unused) in layer_data]),
          layer=','.join([layer for (unused, layer) in layer_data]))
      self.assertEqual(tag, str(name))
      self.assertEqual(published_tag, str(name))
      self.assertEqual(digest.digest, expected_digest)

  def test_publish_fast_stamping(self):
    td = TestData(
        'io_bazel_rules_k8s/examples/hellogrpc/cc/server/server.tar')
    # name = docker_name.Tag('fake.gcr.io/foo/bar:{STABLE_GIT_COMMIT}')
    name = "fake.gcr.io/foo/bar:{STABLE_GIT_COMMIT}"
    stamp_info = { "STABLE_GIT_COMMIT": "9428a3b3" }
    expected_tag = 'fake.gcr.io/foo/bar:9428a3b3'

    with v2_2_image.FromTarball(td) as img:
      (config_path, layer_data) = save.fast(img, self._tmpdir, threads=16)
      expected_digest = img.digest()

    print(expected_digest)
    with mock.patch.object(v2_2_session, 'Push', return_value=NopPush()):
      (tag, published_tag, digest) = resolver.Publish(
          _BAD_TRANSPORT, None, stamp_info, name=name, config=config_path,
          digest=','.join([h for (h, unused) in layer_data]),
          layer=','.join([layer for (unused, layer) in layer_data]))
      self.assertEqual(tag, name)
      self.assertEqual(published_tag, expected_tag)
      self.assertEqual(digest.digest, expected_digest)

if __name__ == '__main__':
  unittest.main()
