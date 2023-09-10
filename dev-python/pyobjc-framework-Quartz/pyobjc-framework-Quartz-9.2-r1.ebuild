# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{10..12} )

inherit distutils-r1

DESCRIPTION="Wrappers for the Quartz frameworks on macOS"
SRC_URI="https://files.pythonhosted.org/packages/49/52/a56bbd76bba721f49fa07d34ac962414b95eb49a9b941fe4d3761f3e6934/pyobjc-framework-Quartz-9.2.tar.gz"
HOMEPAGE="https://github.com/ronaldoussoren/pyobjc"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~arm64-macos"

IUSE=""
RDEPEND=">=dev-python/pyobjc-core-9.2[${PYTHON_USEDEP}]
	>=dev-python/pyobjc-framework-Cocoa-9.2[${PYTHON_USEDEP}]"
distutils_enable_tests pytest
