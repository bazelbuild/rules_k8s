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

#ifndef EXAMPLES_BAZEL_GRPC_CC_SIMPLE_H
#define EXAMPLES_BAZEL_GRPC_CC_SIMPLE_H

#include <memory>
#include <string>
#include <grpc++/grpc++.h>

#include "examples/hellogrpc/proto/simple.pb.h"
#include "examples/hellogrpc/proto/simple.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using proto::FooRequest;
using proto::FooReply;
using proto::Simple;

class SimpleClient {
 public:
  SimpleClient(std::shared_ptr<Channel> channel);

  std::string Foo(const std::string& user);

 private:
  std::unique_ptr<Simple::Stub> stub_;
};

#endif  // EXAMPLES_BAZEL_GRPC_CC_SIMPLE_H
