// Copyright 2017 The Bazel Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include <iostream>

#include "examples/hello-grpc/cc/client/simple.h"

// Constructor with "initialization list"
SimpleClient::SimpleClient(std::shared_ptr<Channel> channel)
  : stub_(Simple::NewStub(channel)) {}

std::string SimpleClient::Foo(const std::string& user) {
  // Data we are sending to the server.
  FooRequest request;
  request.set_name(user);

  // Container for the data we expect from the server.
  FooReply reply;

  // Context for the client. It could be used to convey extra information to
  // the server and/or tweak certain RPC behaviors.
  ClientContext context;

  // The actual RPC.
  Status status = stub_->Foo(&context, request, &reply);

  // Act upon its status.
  if (status.ok()) {
    return reply.message();
  } else {
    return "RPC failed";
  }
}
