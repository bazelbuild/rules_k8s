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
"""Pre-processor for templates.

If the supplied template is json formatted we convert it to yaml such that
code downstream from here only has to deal with one format.
"""

import argparse
import simplejson as json
import sys
import yaml

parser = argparse.ArgumentParser(description='Resolve stamp references.')

parser.add_argument('--input', action='store',
                    help='The json input file.')

parser.add_argument('--output', action='store',
                    help='The output file.')

DOC_DELIMITER = '---\n'

def _process_json(input_str):
  """Converts a json string into a yaml string."""
  data = json.loads(input_str)
  if isinstance(data, list):
    return DOC_DELIMITER.join(yaml.safe_dump(x) for x in data)
  elif isinstance(data, dict):
    return yaml.safe_dump(data)
  else:
    raise ValueError("Invalid json file.")


def main():
  args = parser.parse_args()
  input_str = open(args.input).read()

  if args.input.endswith(".json"):
    output = _process_json(input_str)
  else:
    output = input_str

  with open(args.output, 'w') as f:
    f.write(output)


if __name__ == '__main__':
  main()
