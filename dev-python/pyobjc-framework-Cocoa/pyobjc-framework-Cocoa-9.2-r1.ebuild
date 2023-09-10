# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{10..12} )

inherit distutils-r1

DESCRIPTION="Wrappers for the Cocoa frameworks on macOS"
SRC_URI="https://files.pythonhosted.org/packages/38/91/c54fdffda6d7cfad67ff617f19001163658d50bc72376d1584e691cf4895/pyobjc-framework-Cocoa-9.2.tar.gz"
HOMEPAGE="https://github.com/ronaldoussoren/pyobjc"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~arm64-macos"

IUSE=""
RDEPEND=">=dev-python/pyobjc-core-9.2[${PYTHON_USEDEP}]"
distutils_enable_tests pytest
