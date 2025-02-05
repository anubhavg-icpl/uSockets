Let me help you test each server securely:

1. TCP Server:
```bash
# In terminal 1
./tcp_server

# In terminal 2 (test using netcat)
nc localhost 3000
# Type a message and press Enter
```

2. HTTP Server (need to fix cert path):
```bash
# Fix the server to use correct cert paths
./http_server .certs/cert.pem .certs/key.pem

# Test using curl in another terminal
curl -k https://localhost:3000
```

3. TCP Load Test:
```bash
# First start the tcp_server
./tcp_server

# Then run load test (in another terminal)
./tcp_load_test 100 localhost 3000
```

4. For HTTP/3 server, we need to rebuild with QUIC support:
```bash
make clean
make WITH_BORINGSSL=1 WITH_LTO=1 WITH_QUIC=1
make examples WITH_BORINGSSL=1 WITH_LTO=1 WITH_QUIC=1
```

5. For the Echo Server segfault, let's try rebuilding with debug info and ASAN:
```bash
make clean
make WITH_BORINGSSL=1 WITH_LTO=1 WITH_ASAN=1
make examples WITH_BORINGSSL=1 WITH_LTO=1 WITH_ASAN=1
```

Would you like me to explain how to:
1. Set up proper TLS certificates for the HTTP server?
2. Debug the Echo Server crash?
3. Set up QUIC support?
4. Run load tests safely?