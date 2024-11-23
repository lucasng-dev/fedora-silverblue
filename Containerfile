FROM scratch AS ctx
COPY / /

FROM quay.io/fedora/fedora-silverblue:41
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,src=/,dst=/ctx \
    mkdir -p /var/lib/alternatives && \
    /ctx/build.sh && \
    ostree container commit
