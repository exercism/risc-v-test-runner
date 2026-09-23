# Alpine 3.24 ships everything the runner needs as packages: zig provides the
# whole RISC-V cross toolchain (clang, integrated assembler, lld, and a musl
# libc built on demand), qemu-riscv32 runs the result, and bash, gawk and jq
# turn the test output into results.json.
FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

# We can't reliably pin the package versions on Alpine, so we ignore the linter warning.
# See https://gitlab.alpinelinux.org/alpine/abuild/-/issues/9996
# hadolint ignore=DL3018
#
# zig ships libc headers and sources for every platform it can target. Only
# Linux and musl are reachable from here, so the rest is dropped in the same
# layer, along with the C++ and sanitizer runtimes a C test program never
# links.
RUN apk add --no-cache bash gawk jq make qemu-riscv32 zig \
    && cd /usr/lib/zig \
    && find libc/include -mindepth 1 -maxdepth 1 \
        ! -name 'any-linux-any' ! -name 'generic-musl' \
        ! -name 'riscv-linux-any' ! -name 'riscv32-linux-musl' \
        -exec rm -rf {} + \
    && rm -rf libc/darwin libc/freebsd libc/glibc libc/mingw libc/netbsd \
        libc/openbsd libc/wasi libcxx libcxxabi libtsan docs build-web init

# zig builds musl and compiler_rt for the target on first use and keeps them in
# its global cache. That takes far longer than a solution may run, so the cache
# is filled here, with the target and flags the exercises' Makefile uses, and
# only read afterwards. bin/run.sh copies it to /tmp when it is not writable.
ENV ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache

WORKDIR /tmp/warm
RUN printf 'int main(void) { return 0; }\n' > warm.c \
    && printf '\t.text\n\t.globl warm\nwarm:\n\tret\n' > warm.S \
    && zig cc -target riscv32-linux-musl -std=c23 -g -c -o warm_c.o warm.c \
    && zig cc -target riscv32-linux-musl -c -o warm_s.o warm.S \
    && zig cc -target riscv32-linux-musl -static -o warm warm_c.o warm_s.o \
    && qemu-riscv32 ./warm \
    && cd / \
    && rm -rf /tmp/warm /tmp/zig-cache "${ZIG_GLOBAL_CACHE_DIR}/tmp"

WORKDIR /opt/test-runner
COPY bin/run.sh bin/test-metadata.awk bin/unity-to-json.awk bin/
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
