# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://gitlab.freedesktop.org/pixman/pixman.git"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-r3"
fi

inherit ${GIT_ECLASS} flag-o-matic meson-multilib multiprocessing toolchain-funcs

DESCRIPTION="Low-level pixel manipulation routines"
HOMEPAGE="http://www.pixman.org/ https://gitlab.freedesktop.org/pixman/pixman/"
if [[ ${PV} = 9999* ]]; then
	SRC_URI=""
else
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
	SRC_URI="https://www.x.org/releases/individual/lib/${P}.tar.xz"
fi

LICENSE="MIT"
SLOT="0"
IUSE="cpu_flags_ppc_altivec cpu_flags_arm_iwmmxt cpu_flags_arm_iwmmxt2 cpu_flags_arm_neon loongson2f cpu_flags_x86_mmxext cpu_flags_x86_sse2 cpu_flags_x86_ssse3 static-libs test"
RESTRICT="!test? ( test )"

# see https://gitlab.freedesktop.org/pixman/pixman/-/merge_requests/71
PATCHES=(
	"${FILESDIR}"/${P}-arm64-build-with-llvm.patch
)

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use test && tc-check-openmp
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use test && tc-check-openmp
}

multilib_src_configure() {

	local emesonargs=(
		$(meson_feature cpu_flags_arm_iwmmxt iwmmxt)
		$(meson_use     cpu_flags_arm_iwmmxt2 iwmmxt2)
		$(meson_feature cpu_flags_x86_mmxext mmx)
		$(meson_feature cpu_flags_x86_sse2 sse2)
		$(meson_feature cpu_flags_x86_ssse3 ssse3)
		$(meson_feature cpu_flags_ppc_altivec vmx)
		$(meson_feature loongson2f loongson-mmi)
		$(meson_feature test openmp) # only used in unit tests
		$(meson_feature test tests)
		-Ddefault_library=$(usex static-libs both shared)
		-Dgtk=disabled
		-Dlibpng=disabled
		-Da64-neon=disabled
	)

	# TODO: waiting for a new release
#	if [[ ${ABI} == arm64 ]]; then
#		emesonargs+=($(meson_feature cpu_flags_arm_neon a64-neon))
#	elif [[ ${ABI} == arm ]]; then
#		emesonargs+=($(meson_feature cpu_flags_arm_neon neon))
#	fi

	meson_src_configure
}

multilib_src_test() {
	export OMP_NUM_THREADS=$(makeopts_jobs)
	meson_src_test -t 100
}
