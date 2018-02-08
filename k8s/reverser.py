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
"""Reverses the object order in a multi-document yaml."""

from __future__ import print_function

import argparse


parser = argparse.ArgumentParser(
    description='Reverse a potential multi-document input.')

parser.add_argument(
  '--template', action='store',
  help='The template file to resolve.')

_DOCUMENT_DELIMITER = '---\n'


def main():
  args = parser.parse_args()

  with open(args.template, 'r') as f:
    inputs = f.read()

  content = _DOCUMENT_DELIMITER.join(
    reversed(inputs.split(_DOCUMENT_DELIMITER)))

  print(content)


if __name__ == '__main__':
  main()
