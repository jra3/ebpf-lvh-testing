CLANG ?= clang
LLC ?= llc
ARCH := $(shell uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm64/')

# Include paths for libbpf headers
LIBBPF_INCLUDES := -I/usr/include/bpf

BPF_CFLAGS := -target bpf \
	-D__TARGET_ARCH_$(ARCH) \
	$(LIBBPF_INCLUDES) \
	-Wall \
	-O2 -g \
	-fno-stack-protector

SOURCES := $(wildcard *.c)
OBJECTS := $(SOURCES:.c=.o)

all: $(OBJECTS)

%.o: %.c
	$(CLANG) $(BPF_CFLAGS) -c $< -o $@

clean:
	rm -f *.o

.PHONY: all clean