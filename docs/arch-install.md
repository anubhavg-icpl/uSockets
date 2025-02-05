
# uSockets Setup Guide for Arch Linux

## Prerequisites

Install required packages:
```bash
sudo pacman -S base-devel cmake go openssl git clang
```

## Building from Source

1. Clone the repository:
```bash
git clone https://github.com/uNetworking/uSockets.git
cd uSockets
```

2. Set up BoringSSL (recommended for security):
```bash
git clone https://github.com/google/boringssl.git
cd boringssl
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
cd ../..
```

3. Build uSockets with BoringSSL and security features:
```bash
make clean
make WITH_BORINGSSL=1 WITH_LTO=1
```

4. Generate SSL certificates for HTTPS:
```bash
mkdir .certs
openssl req -x509 -newkey rsa:4096 \
    -keyout .certs/key.pem \
    -out .certs/cert.pem \
    -days 365 -nodes \
    -subj "/CN=localhost"
```

5. Build examples:
```bash
make examples WITH_BORINGSSL=1 WITH_LTO=1
```

## Running Examples

### TCP Server
```bash
# Start server
./tcp_server

# Test with netcat
nc localhost 3000
```

### HTTPS Server
```bash
# Start server with certificates
./http_server .certs/cert.pem .certs/key.pem

# Test with curl
curl -k https://localhost:3000
```

### Load Testing
```bash
# Start server first
./tcp_server

# Run load test with 100 connections
./tcp_load_test 100 localhost 3000
```

### HTTP/3 Support (Optional)
To enable QUIC/HTTP3:
```bash
make clean
make WITH_BORINGSSL=1 WITH_LTO=1 WITH_QUIC=1
make examples WITH_BORINGSSL=1 WITH_LTO=1 WITH_QUIC=1
```

## Security Considerations

1. Certificate Handling:
   - Generated certificates are self-signed - use proper CA-signed certs in production
   - Keep private keys secure (correct permissions on .certs directory)
   - Regularly rotate certificates

2. Network Security:
   - Default port is 3000 - configure firewall appropriately
   - Use BoringSSL over OpenSSL when possible
   - Enable ASAN for testing: add WITH_ASAN=1 to make commands

3. Additional Hardening:
   - Enable compiler protections:
     ```bash
     export CFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2"
     export LDFLAGS="-Wl,-z,now -Wl,-z,relro"
     ```
   - Use secure TLS configurations in production

## Debugging

For debugging crashes or memory issues:
```bash
# Build with debug symbols and ASAN
make clean
make WITH_BORINGSSL=1 WITH_LTO=1 WITH_ASAN=1
```

## Common Issues

1. SSL Certificate errors:
   - Verify certificate paths
   - Check file permissions
   - Ensure certificates are valid

2. Segmentation faults:
   - Run with ASAN to detect memory issues
   - Check for null pointers
   - Verify all dependencies are properly linked

3. Port binding issues:
   - Check if port is already in use
   - Verify permissions
   - Configure firewall rules

## Additional Resources

- [uSockets Documentation](https://github.com/uNetworking/uSockets)
- [BoringSSL Documentation](https://github.com/google/boringssl)
- [Arch Linux Security Guide](https://wiki.archlinux.org/title/Security)
```
