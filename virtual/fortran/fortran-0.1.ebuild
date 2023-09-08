# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Wrapper for flang"

SLOT="0"
KEYWORDS="arm64-macos"
IUSE="openmp"

RDEPEND="
	|| (
		sys-devel/flang
		)"

S="${WORKDIR}"

src_install() {
	# wrapper
	dodir /usr/local/bin
	exeinto /usr/local/bin
	doexe "${FILESDIR}"/gfortran
	# TODO: should be in clang-common
	dodir /etc/clang/
	insinto /etc/clang
	doins "${FILESDIR}"/flang.cfg
}
