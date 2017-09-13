/*
 * Copyright 2017 The Bazel Authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.bazel.rules_k8s.examples.helloworld.java.client;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.StatusRuntimeException;

import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

import io.bazel.rules_k8s.examples.helloworld.proto.SimpleGrpc;
import io.bazel.rules_k8s.examples.helloworld.proto.FooRequest;
import io.bazel.rules_k8s.examples.helloworld.proto.FooReply;

// Based on the gRPC samples from github.com/pubref/rules_protobuf
public class HelloClient {
    private static final Logger logger = Logger.getLogger(HelloClient.class.getName());

    private final ManagedChannel channel;
    private final SimpleGrpc.SimpleBlockingStub blockingStub;

    /** Construct client connecting to Simple server at {@code host:port}. */
    public HelloClient(String host, int port) {
	channel = ManagedChannelBuilder.forAddress(host, port)
	    .usePlaintext(true)
	    .build();
	blockingStub = SimpleGrpc.newBlockingStub(channel);
    }

    public void shutdown() throws InterruptedException {
	channel.shutdown().awaitTermination(5, TimeUnit.SECONDS);
    }

    /** Call method Foo. */
    public String foo(String name) {
	FooRequest request = FooRequest.newBuilder().setName(name).build();
	FooReply response;
	try {
	    response = blockingStub.foo(request);
	    System.out.println("Foo(" + name + "): " + response.getMessage());
	    return response.getMessage();
	} catch (StatusRuntimeException e) {
	    String msg = "RPC failed: " + e.getStatus();
	    logger.log(Level.WARNING, msg);
	    return msg;
	}
    }

    /** Talk to the Simple service */
    public static void main(String[] args) throws Exception {
	HelloClient client = new HelloClient("104.154.73.154", 50051);
	try {
	    String user = "world";
	    if (args.length > 0) {
		user = args[0];
	    }
	    client.foo(user);
	} finally {
	    client.shutdown();
	}
    }

}
