---
tags: [development, api]
---

# WebSocket

A protocol for full-duplex communication over a single TCP connection.

## Key Features

- **Full-duplex** — Simultaneous bidirectional communication
- **Low latency** — Persistent connection reduces overhead
- **Real-time** — Ideal for live data and events
- **Web standard** — Supported in all modern browsers

## Connection Handshake

Client sends HTTP upgrade request:

```
GET /websocket HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
```

Server responds:

```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```

## Usage Example

```javascript
// Client-side
import io from 'socket.io-client';

const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('connected');
});

socket.emit('chat message', 'Hello from client!');
```

## References

- [WebSocket Protocol](https://tools.ietf.org/html/rfc6455)
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)