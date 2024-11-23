FROM scratch AS ctx
COPY / /

FROM quay.io/fedora-ostree-desktops/silverblue:41
COPY build.sh /tmp/build.sh
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,src=/,dst=/ctx \
    mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit
