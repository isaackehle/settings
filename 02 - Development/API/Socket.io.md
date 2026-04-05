---
tags: [development, api, realtime]
---

# <img src="https://github.com/socketio.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Socket.io

Real-time, bidirectional and event-based communication library for web applications.

## Installation

```shell
npm install socket.io
```

## Key Features

- **Real-time communication** — Bidirectional event-based communication
- **Automatic reconnection** — Handles connection drops gracefully
- **Room support** — Group clients into rooms for targeted messaging
- **Namespace support** — Separate communication channels
- **Fallback support** — Falls back to HTTP polling when WebSocket unavailable

## Basic Usage

```javascript
// Server
const io = require('socket.io')(3000);

io.on('connection', (socket) => {
  console.log('a user connected');

  socket.on('chat message', (msg) => {
    io.emit('chat message', msg);
  });
});

// Client
import io from 'socket.io-client';

const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('connected');
});

socket.emit('chat message', 'Hello from client!');
```

## References

- [Socket.io Documentation](https://socket.io/docs/)
- [Socket.io GitHub](https://github.com/socketio/socket.io)