#!/bin/bash
set -eux -o pipefail

# prepare
tmpdir=$(mktemp -d) && pushd "$tmpdir"

# helper
mv-opt-lib() {
	local opt_dir=$1 lib_dir=$2
	mv "$opt_dir" "$lib_dir"
	search_dirs=("$lib_dir" /usr/share/{applications,appdata,gnome-control-center/default-apps})
	{ grep -rl "$opt_dir" "${search_dirs[@]}" 2>/dev/null || true; } | xargs sed -i "s|$opt_dir|$lib_dir|g"
}

# base packages
rpm-ostree install --idempotent \
	langpacks-{en,pt} \
	zsh eza bat micro mc \
	fzf fd-find ripgrep ncdu tldr tmux \
	btop htop xclip xsel wl-clipboard \
	iperf3 firewall-config syncthing tailscale \
	distrobox podman{,-compose} docker{,-compose} \
	btrfs-assistant gparted p7zip{,-plugins} cabextract \
	cups-pdf gnome-themes-extra gnome-tweaks tilix \
	wireguard-tools \
	openrgb \
	virt-manager \
	onedrive

# repo: google-chrome
sed -i '\/enabled=/c\enabled=1' /etc/yum.repos.d/google-chrome.repo >/dev/null

# repo: microsoft-edge -> https://www.microsoft.com/edge/download
cat >/etc/yum.repos.d/microsoft-edge.repo <<-"EOF"
	[microsoft-edge]
	name=Microsoft Edge
	baseurl=https://packages.microsoft.com/yumrepos/edge
	enabled=1
	gpgcheck=1
	gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# repo: tailscale -> https://pkgs.tailscale.com/stable/fedora/tailscale.repo
cat >/etc/yum.repos.d/tailscale.repo <<-"EOF"
	[tailscale-stable]
	name=Tailscale stable
	baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
	enabled=1
	type=rpm
	repo_gpgcheck=1
	gpgcheck=1
	gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
EOF

# repo: 1password -> https://support.1password.com/install-linux/#fedora-or-red-hat-enterprise-linux
cat >/etc/yum.repos.d/1password.repo <<-"EOF"
	[1password]
	name=1Password Stable Channel
	baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# install
mkdir /var/opt
dnf5 install -y 1password{,-cli} google-chrome-stable microsoft-edge-stable tailscale \
	https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

# 1password - https://github.com/bsherman/bos/blob/main/build_files/desktop-1password.sh
mv-opt-lib /opt/1Password /usr/lib/1Password
ln -srf /usr/lib/1Password/1password /usr/bin/1password
chmod 4755 /usr/lib/1Password/chrome-sandbox

# chrome
mv-opt-lib /opt/google/chrome /usr/lib/google-chrome
ln -srf /usr/lib/google-chrome/google-chrome /usr/bin/google-chrome-stable

# edge
mv-opt-lib /opt/microsoft/msedge /usr/lib/microsoft-edge
ln -srf /usr/lib/microsoft-edge/microsoft-edge /usr/bin/microsoft-edge-stable

# cleanup
rpm-ostree override remove ublue-os-just just nvtop
rm -f /etc/yum.repos.d/{1password,tailscale,google-chrome,microsoft-edge}.repo

# cleanup
rpm-ostree cleanup -m
popd && rm -rf "$tmpdir"
