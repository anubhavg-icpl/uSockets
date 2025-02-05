# By default we use LTO, but Windows does not support it
ifneq ($(WITH_LTO),0)
    override CFLAGS += -flto
endif

# WITH_BORINGSSL=1 enables BoringSSL support, linked statically (preferred over OpenSSL)
# You need to call "make boringssl" before
ifeq ($(WITH_BORINGSSL),1)
    override CFLAGS += -Iboringssl/include -pthread -DLIBUS_USE_OPENSSL
    override LDFLAGS += -pthread $(shell pwd)/boringssl/build/ssl/libssl.a $(shell pwd)/boringssl/build/crypto/libcrypto.a -lstdc++
else
    # WITH_OPENSSL=1 enables OpenSSL 1.1+ support
    ifeq ($(WITH_OPENSSL),1)
        override CFLAGS += -DLIBUS_USE_OPENSSL
        override LDFLAGS += -lssl -lcrypto -lstdc++
    else
        # WITH_WOLFSSL=1 enables WolfSSL 4.2.0 support (mutually exclusive with OpenSSL)
        ifeq ($(WITH_WOLFSSL),1)
            override CFLAGS += -DLIBUS_USE_WOLFSSL -I/usr/local/include
            override LDFLAGS += -L/usr/local/lib -lwolfssl
        else
            override CFLAGS += -DLIBUS_NO_SSL
        endif
    endif
endif

# WITH_IO_URING=1 builds with io_uring as event-loop and network implementation
ifeq ($(WITH_IO_URING),1)
    override CFLAGS += -DLIBUS_USE_IO_URING
endif

# WITH_LIBUV=1 builds with libuv as event-loop
ifeq ($(WITH_LIBUV),1)
    override CFLAGS += -DLIBUS_USE_LIBUV
    override LDFLAGS += -luv
endif

# WITH_ASIO builds with boost asio event-loop
ifeq ($(WITH_ASIO),1)
    override CFLAGS += -DLIBUS_USE_ASIO
    override LDFLAGS += -lstdc++ -lpthread
    override CXXFLAGS += -pthread -DLIBUS_USE_ASIO
endif

# WITH_GCD=1 builds with libdispatch as event-loop
ifeq ($(WITH_GCD),1)
    override CFLAGS += -DLIBUS_USE_GCD
    override LDFLAGS += -framework CoreFoundation
endif

# WITH_ASAN builds with sanitizers
ifeq ($(WITH_ASAN),1)
    override CFLAGS += -fsanitize=address -g
    override LDFLAGS += -fsanitize=address
endif

# QUIC support
ifeq ($(WITH_QUIC),1)
    override CFLAGS += -DLIBUS_USE_QUIC -pthread -std=c11 -Isrc -Ilsquic/include
    override LDFLAGS += -pthread -lz -lm lsquic/src/liblsquic/liblsquic.a
else
    override CFLAGS += -std=c11 -Isrc
endif

# Also link liburing for io_uring support
ifeq ($(WITH_IO_URING),1)
    override LDFLAGS += /usr/lib/liburing.a
endif

# Object files
OBJECTS = $(patsubst %.c,%.o,$(wildcard src/*.c src/eventing/*.c src/crypto/*.c src/io_uring/*.c))
CPP_OBJECTS = $(patsubst %.cpp,%.o,$(wildcard src/crypto/*.cpp))

# By default we build the uSockets.a static library
default: uSockets.a

uSockets.a: $(OBJECTS) $(CPP_OBJECTS)
	$(AR) rcs $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -O3 -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -std=c++17 -flto -O3 -c $< -o $@

# BoringSSL needs cmake and golang
.PHONY: boringssl
boringssl:
	cd boringssl && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j8

# Builds all examples
# Builds all examples
.PHONY: examples
examples: default
	for f in examples/*.c; do \
		$(CC) -O3 $(CFLAGS) -o "$$(basename "$$f" ".c")" "$$f" \
		$(shell pwd)/uSockets.a \
		$(shell pwd)/boringssl/build/ssl/libssl.a \
		$(shell pwd)/boringssl/build/crypto/libcrypto.a \
		-pthread -lstdc++; \
	done
	
swift_examples: default
	swiftc -O -I . examples/swift_http_server/main.swift uSockets.a -o swift_http_server

.PHONY: clean
clean:
	rm -f src/*.o src/eventing/*.o src/crypto/*.o src/io_uring/*.o
	rm -f *.a
	rm -rf .certs

.PHONY: all
all: default examples