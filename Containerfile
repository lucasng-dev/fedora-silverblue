ARG IMAGE_SOURCE=quay.io/fedora/fedora-silverblue
ARG IMAGE_VERSION=latest

FROM scratch AS ctx
COPY / /

FROM ${IMAGE_SOURCE}:${IMAGE_VERSION}
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=bind,from=ctx,src=/,dst=/ctx \
    cp -r /ctx/rootfs/* / && /ctx/build.sh
