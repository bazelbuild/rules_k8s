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
"""Resolve stamp variables."""

import argparse
import sys

parser = argparse.ArgumentParser(description='Resolve stamp references.')

parser.add_argument('--format', action='store',
                    help='The format string containing stamp variables.')

parser.add_argument('--output', action='store',
                    help='The filename into which we write the result.')

parser.add_argument('--stamp-info-file', action='append', required=False,
                    help=('A list of files from which to read substitutions '
                          'to make in the provided --name, e.g. {BUILD_USER}'))

def main():
  args = parser.parse_args()

  # Read our stamp variable files.
  format_args = {}
  for infofile in args.stamp_info_file or []:
    with open(infofile) as info:
      for line in info:
        line = line.strip('\n')
        if not line:
          continue
        elts = line.split(' ', 1)
        if len(elts) != 2:
          raise Exception('Malformed line: %s' % line)
        (key, value) = elts
        if key in format_args:
          print ('WARNING: Duplicate value for key "%s": '
                 'using "%s"' % (key, value))
        format_args[key] = value

  with open(args.output, 'w') as f:
    f.write(args.format.format(**format_args))


if __name__ == '__main__':
  main()
