FROM alpine:3.19


COPY scripts/install_deps.sh /tmp/install_deps.sh
RUN chmod +x /tmp/install_deps.sh && /tmp/install_deps.sh && rm /tmp/install_deps.sh

WORKDIR /work
