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
"""Python hellogrpc service implementation."""

import grpc
import time

from concurrent import futures
from examples.hellogrpc.proto import simple_pb2
from examples.hellogrpc.proto import simple_pb2_grpc


class _SimpleService(simple_pb2_grpc.SimpleServicer):

    def Foo(self, foo_request, context):
        foo_reply = simple_pb2.FooReply()
        foo_reply.message = 'DEMO {name}'.format(name=foo_request.name)
        return foo_reply


class _HelloServer(object):

    def __init__(self, simple_service, server_port):
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
        simple_pb2_grpc.add_SimpleServicer_to_server(simple_service, self.server)
        self.server.add_insecure_port('[::]:{server_port}'.format(server_port=server_port))

    def start(self):
        self.server.start()

    def stop(self):
        self.server.stop(0)

    def await_termination(self):
        try:
            while True:
                time.sleep(60 * 60)
        except KeyboardInterrupt:
            self.server.stop(0)


def main():
    port = 50051
    hello_server = _HelloServer(_SimpleService(), port)
    print("Server listening at :%d..." % port)
    hello_server.start()
    hello_server.await_termination()

if __name__ == '__main__':
    main()
