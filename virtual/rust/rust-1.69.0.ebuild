# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib-build

DESCRIPTION="Virtual for Rust language compiler"

LICENSE=""

# adjust when rust upstream bumps internal llvm
# we do not allow multiple llvm versions in dev-lang/rust for
# neither system nor bundled, so we just hardcode it here.
SLOT="0/llvm-15"
KEYWORDS="arm64-macos"
IUSE="rustfmt"

BDEPEND=""
RDEPEND="|| (
	~dev-lang/rust-${PV}[rustfmt?,${MULTILIB_USEDEP}]
	~dev-lang/rust-bin-macos-${PV}[rustfmt?,${MULTILIB_USEDEP}]
)"
