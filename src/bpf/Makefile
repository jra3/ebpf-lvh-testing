CLANG ?= clang
LLC ?= llc
ARCH := $(shell uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm64/')

# Try to find kernel headers
KERNEL_HEADERS := /usr/include
ifneq ($(wildcard /usr/include/linux/bpf.h),)
    BPF_INCLUDES = -I/usr/include
else ifneq ($(wildcard /usr/src/linux-headers-$(shell uname -r)/include),)
    BPF_INCLUDES = -I/usr/src/linux-headers-$(shell uname -r)/include
endif

BPF_CFLAGS := -target bpf \
	-D__TARGET_ARCH_$(ARCH) \
	$(BPF_INCLUDES) \
	-Wall \
	-O2 -g

SOURCES := $(wildcard *.c)
OBJECTS := $(SOURCES:.c=.o)

all: minimal.o

%.o: %.c
	$(CLANG) $(BPF_CFLAGS) -c $< -o $@

clean:
	rm -f *.o

.PHONY: all clean