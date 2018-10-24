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
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"

	pb "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go"
	"google.golang.org/grpc"
)

var port = flag.String("port", "50051", "port to listen")

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%s", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	log.Printf("Server listening on :%s...", *port)
	s := grpc.NewServer()
	pb.RegisterSimpleServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

type server struct{}

func (s *server) Foo(ctx context.Context, req *pb.FooRequest) (*pb.FooReply, error) {
	return &pb.FooReply{
		Message: fmt.Sprintf("DEMO %s", req.Name),
	}, nil
}
