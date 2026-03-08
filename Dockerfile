FROM rust:alpine AS builder
RUN apk add --no-cache build-base git openssl-dev pkgconf openssl-libs-static
RUN cargo install cargo-c
RUN git clone https://github.com/biscuit-auth/biscuit-rust.git /tmp/biscuit && \
    cd /tmp/biscuit/biscuit-capi && \
    cargo cinstall --release --library-type=staticlib --prefix=/usr/local --destdir=/out && \
    find /out

FROM alpine:3.19

COPY --from=builder /out/usr/local/include/biscuit_capi/biscuit_auth.h /usr/local/include/
COPY --from=builder /out/usr/local/lib/libbiscuit_auth.a /usr/local/lib/

COPY scripts/install_deps.sh /tmp/install_deps.sh
RUN chmod +x /tmp/install_deps.sh && /tmp/install_deps.sh && rm /tmp/install_deps.sh

WORKDIR /work
