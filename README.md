# Fedora Silverblue (custom build)

[![build-fedora-silverblue](https://github.com/lucasng-dev/fedora-silverblue/actions/workflows/build.yml/badge.svg)](https://github.com/lucasng-dev/fedora-silverblue/actions/workflows/build.yml)

Custom Fedora Silverblue OCI image based on Fedora Silverblue [official image](https://quay.io/repository/fedora/fedora-silverblue).

Scripts based on [ublue-os/main](https://github.com/ublue-os/main).

## Usage

```sh
rpm-ostree rebase ostree-unverified-image:registry:ghcr.io/lucasng-dev/fedora-silverblue:latest
```
