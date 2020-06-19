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

#include "examples/hellogrpc/cc/client/simple.h"

int main(int argc, char** argv) {
  if (argc != 2) {
    std::cerr << "Expected single IP address argument." << std::endl;
    return 1;
  }
  std::string address(argv[1]);
  address.append(":50051");

  // Instantiate the client. It requires a channel, out of which the
  // actual RPCs are created. This channel models a connection to an
  // endpoint (in this case, localhost at port 50051). We indicate
  // that the channel isn't authenticated (use of InsecureCredentials()).
  SimpleClient simple(grpc::CreateChannel(address, grpc::InsecureChannelCredentials()));
  std::string user("world");

  std::string resp(simple.Foo(user));
  if (resp == "RPC failed") {
      std::cerr << resp << std::endl;
      return 1;
  } 

  std::cout << "Foo(" << user << "): " << resp << std::endl;
  return 0;
}
