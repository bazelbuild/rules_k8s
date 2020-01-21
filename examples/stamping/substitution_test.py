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

import os
import subprocess
import unittest
import yaml

def TestData(name):
  return os.path.join(os.environ['TEST_SRCDIR'], 'io_bazel_rules_k8s', name)

class DeploymentTest(unittest.TestCase):

  def test_username_substituted(self):
    k8s_obj = TestData('examples/stamping/substitution_stamping')
    out = subprocess.check_output([k8s_obj])
    generated = yaml.load(out)

    self.assertRegexpMatches(
        generated['data']['e2e_namespace'],
        r"^build-.+$",
    )

if __name__ == '__main__':
  unittest.main()
