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
package io.bazel.rules_k8s.examples.helloworld.java.server;

import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.stub.StreamObserver;

import java.io.IOException;
import java.util.logging.Logger;

import io.bazel.rules_k8s.examples.helloworld.proto.SimpleGrpc;
import io.bazel.rules_k8s.examples.helloworld.proto.FooRequest;
import io.bazel.rules_k8s.examples.helloworld.proto.FooReply;

// Based on the gRPC samples from github.com/pubref/rules_protobuf
public class HelloServer {
    private static final Logger logger = Logger.getLogger(HelloServer.class.getName());

    private final int port;
    private Server server;

    public HelloServer() {
	this(50051);
    }

    public HelloServer(int port) {
	this.port = port;
    }

    public void start() throws IOException {
	server = ServerBuilder.forPort(port)
	    .addService(new SimpleImpl())
	    .build()
	    .start();
	logger.info("Server started, listening on " + port);
	Runtime.getRuntime().addShutdownHook(new Thread() {
		@Override
		public void run() {
		    // Use stderr here since the logger may have been reset by its JVM shutdown hook.
		    System.err.println("*** shutting down gRPC server since JVM is shutting down");
		    HelloServer.this.stop();
		    System.err.println("*** server shut down");
		}
	    });
    }

    public void stop() {
	if (server != null) {
	    server.shutdown();
	}
    }

    /** Await termination on the main thread since the grpc library uses daemon threads. */
    private void blockUntilShutdown() throws InterruptedException {
	if (server != null) {
	    server.awaitTermination();
	}
    }

    /** Main launches the server from the command line. */
    public static void main(String[] args) throws IOException, InterruptedException {
	final HelloServer server = new HelloServer();
	server.start();
	server.blockUntilShutdown();
    }

    private class SimpleImpl extends SimpleGrpc.SimpleImplBase {
	@Override
	public void foo(FooRequest req, StreamObserver<FooReply> responseObserver) {
	    FooReply reply = FooReply.newBuilder().setMessage("DEMO " + req.getName()).build();
	    responseObserver.onNext(reply);
	    responseObserver.onCompleted();
	}
    }
}
