# Add gRPC Service

Add a new gRPC service to the API.

Create a new gRPC service for {{SERVICE_NAME}}:
1. Define protobuf schema in internal/adapters/grpc/proto/
2. Generate Go code from protobuf
3. Implement service interface in internal/adapters/grpc/
4. Map use cases to gRPC methods
5. Add proper error handling with gRPC status codes
6. Implement request validation
7. Add interceptors for logging/auth if needed
8. Write integration tests
9. Update server registration