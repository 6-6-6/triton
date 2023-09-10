# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

inherit distutils-r1 prefix

DESCRIPTION="Python<->ObjC Interoperability Module"
SRC_URI="https://files.pythonhosted.org/packages/48/d9/a13566ce8914746557b9e8637a5abe1caae86ed202b0fb072029626b8bb1/pyobjc-core-9.2.tar.gz"
HOMEPAGE="https://github.com/ronaldoussoren/pyobjc"

S="${WORKDIR}"/${P}

LICENSE="MIT"
SLOT="0"
KEYWORDS="~arm64-macos"


distutils_enable_tests pytest

PATCHES=(
	"${FILESDIR}"/${PN}-9.2-sysroot-in-prefix.patch
)
