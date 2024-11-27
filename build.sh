#!/bin/bash
set -eux -o pipefail
cd "$(mktemp -d)"

# persist additional build-time locations (see also: 'rootfs/usr/lib/tmpfiles.d/zz-custom.conf')
mkdir -p /usr/lib/{opt,usrlocal,alternatives} /var/lib
ln -sfT /usr/lib/opt /var/opt
ln -sfT /usr/lib/usrlocal /var/usrlocal
ln -sfT /usr/lib/alternatives /var/lib/alternatives

# enable rpm repos
cp /etc/yum.repos.d/rpmfusion-nonfree-steam.repo /etc/yum.repos.d/rpmfusion-nonfree-steam.repo.bak
sed -Ei '0,/^enabled=.*$/s//enabled=1/' /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
wget -O /etc/yum.repos.d/tailscale.repo -q https://pkgs.tailscale.com/stable/fedora/tailscale.repo

# remove rpm packages
dnf remove -y \
	gnome-software-fedora-langpacks firefox

# install rpm packages
dnf install -y \
	langpacks-{en,pt} \
	zsh eza bat micro mc \
	lsb_release fzf fd-find ripgrep tree ncdu tldr bc rsync tmux \
	btop htop nvtop inxi lm_sensors xclip xsel wl-clipboard \
	openssl curl wget net-tools telnet traceroute mtr bind-utils mtr nmap netcat whois \
	iperf3 speedtest-cli wireguard-tools firewall-config syncthing \
	p7zip{,-plugins} zip unzip unrar unar cabextract \
	cmatrix lolcat fastfetch onefetch \
	git{,-lfs,-delta} gh direnv jq yq \
	distrobox podman{,-compose,-docker,-tui} \
	btrfs-assistant gparted parted \
	cups-pdf gnome-themes-extra gnome-tweaks tilix \
	openrgb steam-devices \
	virt-manager \
	onedrive python3-{pyside6,requests} \
	tailscale \
	https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

# cleanup rpm repos
mv -f /etc/yum.repos.d/rpmfusion-nonfree-steam.repo.bak /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
rm -f /etc/yum.repos.d/tailscale.repo

# enable rpm-ostree automatic updates
sed -Ei '/AutomaticUpdatePolicy=/c\AutomaticUpdatePolicy=stage' /etc/rpm-ostreed.conf >/dev/null
systemctl enable rpm-ostreed-automatic.timer

# enable flatpak automatic updates
(
	git clone --branch=main --depth=1 https://github.com/ublue-os/config.git ublue-config
	for dirname in system{,-preset} user{,-preset}; do
		src="ublue-config/files/usr/lib/systemd/$dirname"
		dest="/usr/lib/systemd/$dirname" && mkdir -p "$dest"
		cp "$src"/*flatpak* "$dest/"
	done
	rm -rf ublue-config
)
systemctl enable flatpak-system-update.timer
systemctl --global enable flatpak-user-update.timer

# enable podman services
sed -Ei 's|(--filter)|--filter restart-policy=unless-stopped \1|g' /usr/lib/systemd/system/podman-restart.service >/dev/null
systemctl enable podman.socket
systemctl --global enable podman.socket
systemctl enable podman-restart.service
systemctl --global enable podman-restart.service

# disable sshd service by default
systemctl disable sshd.service

# enable virt-manager service
systemctl enable libvirtd.service

# enable tailscale service
systemctl enable tailscaled.service

# configure udisks2
udisks2_generate() {
	({ set +x; } &>/dev/null && echo "$(grep -Eo "\b$1=.+" /etc/udisks2/mount_options.conf.example | tail -n 1),$2")
}
cat >/etc/udisks2/mount_options.conf <<-EOF
	[defaults]
	$(udisks2_generate 'ntfs_defaults' 'dmask=0022,fmask=0133,noatime')
	$(udisks2_generate 'exfat_defaults' 'dmask=0022,fmask=0133,noatime')
	$(udisks2_generate 'vfat_defaults' 'dmask=0022,fmask=0133,noatime')
EOF

# fix gnome-disk-image-mounter to mount writable by default
sed -Ei 's|(^Exec=gnome-disk-image-mounter\b)|\1 --writable|g' /usr/share/applications/gnome-disk-image-mounter.desktop

# install onedrive-gui from github main branch
git clone --branch=main --depth=1 https://github.com/bpozdena/OneDriveGUI.git /usr/lib/OneDriveGUI
rm -rf /usr/lib/OneDriveGUI/.git
ln -sfT /usr/share/applications/OneDriveGUI.desktop /etc/xdg/autostart/OneDriveGUI.desktop

# install cloudflared from github releases
wget -q -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x /usr/bin/cloudflared
/usr/bin/cloudflared --version
