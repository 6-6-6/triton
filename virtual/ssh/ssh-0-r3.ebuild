# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for SSH client and server"

SLOT="0"
KEYWORDS="arm64-macos"
IUSE="minimal"

RDEPEND=""

S="${WORKDIR}"

HOST_SSHS=(
	/usr/bin/scp
	/usr/bin/sftp
	/usr/bin/ssh
	/usr/bin/ssh-add
	/usr/bin/ssh-agent
	/usr/bin/ssh-copy-id
	/usr/bin/ssh-keygen
	/usr/bin/ssh-keyscan
)

src_install() {
	# links to host ssh
	dodir /usr/local/bin
	
	for f in ${HOST_SSHS[@]};do
		ln -s ${f} ${ED}/usr/local/bin
	done
}
