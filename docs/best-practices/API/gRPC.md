---
tags: [development, api]
---

# gRPC

A high-performance, open-source universal RPC framework.

## Key Features

- **Protocol Buffers** — Efficient binary serialization
- **HTTP/2** — Modern transport protocol
- **Streaming** — Bidirectional streaming support
- **Language Agnostic** — Works across different languages

## Service Definition

```protobuf
service UserService {
  rpc GetUser (UserRequest) returns (UserResponse);
  rpc CreateUser (CreateUserRequest) returns (UserResponse);
}
```

## Usage

```bash
# Generate code from .proto files
protoc --go_out=. user.proto
```

## References

- [gRPC Documentation](https://grpc.io/)