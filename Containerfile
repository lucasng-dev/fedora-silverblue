FROM scratch AS ctx
COPY / /

FROM quay.io/fedora/fedora-silverblue:41
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=bind,from=ctx,src=/,dst=/ctx \
    cp -r /ctx/rootfs/* / && /ctx/build.sh
