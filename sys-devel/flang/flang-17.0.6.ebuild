# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

inherit cmake flag-o-matic llvm llvm.org multilib multilib-minimal
inherit prefix python-single-r1 toolchain-funcs

DESCRIPTION="C language family frontend for LLVM"
HOMEPAGE="https://llvm.org/"

# MSVCSetupApi.h: MIT
# sorttable.js: MIT

LICENSE="Apache-2.0-with-LLVM-exceptions UoI-NCSA MIT"
SLOT="${LLVM_MAJOR}/${LLVM_SOABI}"
KEYWORDS="~arm64-macos"
#KEYWORDS=""
IUSE="debug doc ieee-long-double +pie +static-analyzer test xml"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="!test? ( test )"

DEPEND="
	~sys-devel/llvm-${PV}:${LLVM_MAJOR}=[debug=,${MULTILIB_USEDEP}]
	~sys-devel/mlir-${PV}:${LLVM_MAJOR}=[debug=,${MULTILIB_USEDEP}]
	static-analyzer? ( dev-lang/perl:* )
	xml? ( dev-libs/libxml2:2=[${MULTILIB_USEDEP}] )
"

RDEPEND="
	${PYTHON_DEPS}
	${DEPEND}
	>=sys-devel/clang-common-${PV}
"
BDEPEND="
	${PYTHON_DEPS}
	>=dev-build/cmake-3.16
	doc? ( $(python_gen_cond_dep '
		dev-python/recommonmark[${PYTHON_USEDEP}]
		dev-python/sphinx[${PYTHON_USEDEP}]
	') )
	xml? ( virtual/pkgconfig )
"
PDEPEND="
	~sys-devel/clang-runtime-${PV}
	sys-devel/clang-toolchain-symlinks:${LLVM_MAJOR}
"

LLVM_COMPONENTS=(
	flang cmake
)
LLVM_MANPAGES=1
LLVM_TEST_COMPONENTS=(
	llvm/lib/Testing
	llvm/utils
	third-party
)
LLVM_USE_TARGETS=llvm
llvm.org_set_globals

# Multilib notes:
# 1. ABI_* flags control ABIs libclang* is built for only.
# 2. clang is always capable of compiling code for all ABIs for enabled
#    target. However, you will need appropriate crt* files (installed
#    e.g. by sys-devel/gcc and sys-libs/glibc).
# 3. ${CHOST}-clang wrappers are always installed for all ABIs included
#    in the current profile (i.e. alike supported by sys-devel/gcc).
#
# Therefore: use sys-devel/clang[${MULTILIB_USEDEP}] only if you need
# multilib clang* libraries (not runtime, not wrappers).

pkg_setup() {
#	LLVM_MAX_SLOT=${LLVM_MAJOR} llvm_pkg_setup
	python-single-r1_pkg_setup
}

src_prepare() {
	# create extra parent dir for relative CLANG_RESOURCE_DIR access
	mkdir -p x/y || die
	BUILD_DIR=${WORKDIR}/x/y/flang

	llvm.org_src_prepare

	# add Gentoo Portage Prefix for Darwin (see prefix-dirs.patch)
#	eprefixify \
#		lib/Lex/InitHeaderSearch.cpp \
#		lib/Driver/ToolChains/Darwin.cpp || die

	if ! use prefix-guest && [[ -n ${EPREFIX} ]]; then
		sed -i "/LibDir.*Loader/s@return \"\/\"@return \"${EPREFIX}/\"@" lib/Driver/ToolChains/Linux.cpp || die
	fi
}

check_distribution_components() {
	if [[ ${CMAKE_MAKEFILE_GENERATOR} == ninja ]]; then
		local all_targets=() my_targets=() l
		cd "${BUILD_DIR}" || die

		while read -r l; do
			if [[ ${l} == install-*-stripped:* ]]; then
				l=${l#install-}
				l=${l%%-stripped*}

				case ${l} in
					# meta-targets
					flang-libraries|distribution)
						continue
						;;
					# tools
					flang|flangd|flang-*)
						;;
					# static libraries
					flang*|findAllSymbols)
						continue
						;;
					# conditional to USE=doc
					docs-flang-html|docs-flang-tools-html)
						use doc || continue
						;;
				esac

				all_targets+=( "${l}" )
			fi
		done < <(${NINJA} -t targets all)

		while read -r l; do
			my_targets+=( "${l}" )
		done < <(get_distribution_components $"\n")

		local add=() remove=()
		for l in "${all_targets[@]}"; do
			if ! has "${l}" "${my_targets[@]}"; then
				add+=( "${l}" )
			fi
		done
		for l in "${my_targets[@]}"; do
			if ! has "${l}" "${all_targets[@]}"; then
				remove+=( "${l}" )
			fi
		done

		if [[ ${#add[@]} -gt 0 || ${#remove[@]} -gt 0 ]]; then
			eqawarn "get_distribution_components() is outdated!"
			eqawarn "   Add: ${add[*]}"
			eqawarn "Remove: ${remove[*]}"
		fi
		cd - >/dev/null || die
	fi
}

get_distribution_components() {
	local sep=${1-;}

	local out=(
		# common stuff
		FIRAnalysis
		FIRBuilder
		FIRCodeGen
		FIRDialect
		FIRSupport
		FIRTransforms
		FortranCommon
		FortranDecimal
		FortranEvaluate
		FortranLower
		FortranParser
		FortranRuntime
		FortranSemantics
		Fortran_main
		HLFIRDialect
		HLFIRTransforms
		bbc
		f18-parse-demo
		fir-opt
		flang-cmake-exports
		flang-new
		tco
	)
	local out=(
		flang-new
	)

	printf "%s${sep}" "${out[@]}"
}

multilib_src_configure() {
	tc-is-gcc && filter-lto # GCC miscompiles LLVM, bug #873670

	local mycmakeargs=(
		#
		-DLLVM_DIR="$(get_llvm_prefix)/lib/cmake/llvm"
		-DCLANG_DIR="$(get_llvm_prefix)/lib/cmake/clang"
		-DMLIR_DIR="$(get_llvm_prefix)/lib/cmake/mlir"
		-DDEFAULT_SYSROOT=$(usex prefix-guest "" "${EPREFIX}")
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}"
		-DCMAKE_INSTALL_MANDIR="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/share/man"

		-DBUILD_SHARED_LIBS=OFF
		-DCLANG_LINK_CLANG_DYLIB=ON
		-DLLVM_DISTRIBUTION_COMPONENTS=$(get_distribution_components)

		-DLLVM_TARGETS_TO_BUILD="${LLVM_TARGETS// /;}"

		# these are not propagated reliably, so redefine them
		## TODO: fuck flang
		-DLLVM_ENABLE_EH=OFF
		-DLLVM_ENABLE_RTTI=ON

	)
	# assign mlir-tblgen
	local tools_bin=${BROOT}/usr/lib/llvm/${LLVM_MAJOR}/bin
	mycmakeargs+=(
		-DLLVM_TOOLS_BINARY_DIR="${tools_bin}"
		-DMLIR_TABLEGEN="${tools_bin}"/mlir-tblgen
	)


	use test || mycmakeargs+=(
		-DFLANG_INCLUDE_TESTS=OFF
	)
	use test && mycmakeargs+=(
		-DLLVM_LIT_ARGS="$(get_lit_flags)"
	)

	if multilib_is_native_abi; then
		local build_docs=OFF
		if llvm_are_manpages_built; then
			build_docs=ON
			mycmakeargs+=(
				-DLLVM_BUILD_DOCS=ON
				-DLLVM_ENABLE_SPHINX=ON
				-DSPHINX_WARNINGS_AS_ERRORS=OFF
			)
		fi
	fi


	# LLVM can have very high memory consumption while linking,
	# exhausting the limit on 32-bit linker executable
	use x86 && local -x LDFLAGS="${LDFLAGS} -Wl,--no-keep-memory"

	# LLVM_ENABLE_ASSERTIONS=NO does not guarantee this for us, #614844
	use debug || local -x CPPFLAGS="${CPPFLAGS} -DNDEBUG"
	export CMAKE_BUILD_TYPE="Release"
	cmake_src_configure

	multilib_is_native_abi && check_distribution_components
}

multilib_src_compile() {
	#cmake_build distribution
	cmake_build

	# provide a symlink for tests
	if [[ ! -L ${WORKDIR}/lib/clang ]]; then
		mkdir -p "${WORKDIR}"/lib || die
		ln -s "${BUILD_DIR}/$(get_libdir)/clang" "${WORKDIR}"/lib/clang || die
	fi
}

multilib_src_test() {
	# respect TMPDIR!
	local -x LIT_PRESERVES_TMP=1
	local test_targets=( check-clang )
	cmake_build "${test_targets[@]}"
}

src_install() {
	#DESTDIR=${D} cmake_build install-distribution
	ewarn probably you need to manually redirect flang/ to ???
	cmake_src_install
}

multilib_src_install_all() {
	python_fix_shebang "${ED}"
	if use static-analyzer; then
		python_optimize "${ED}"/usr/lib/llvm/${LLVM_MAJOR}/share/scan-view
	fi

	docompress "/usr/lib/llvm/${LLVM_MAJOR}/share/man"
	llvm_install_manpages
	# match 'html' non-compression
	use doc && docompress -x "/usr/share/doc/${PF}/tools-extra"
	# +x for some reason; TODO: investigate
	use static-analyzer && fperms a-x "/usr/lib/llvm/${LLVM_MAJOR}/share/man/man1/scan-build.1"
}

pkg_postinst() {
	if [[ -z ${ROOT} && -f ${EPREFIX}/usr/share/eselect/modules/compiler-shadow.eselect ]] ; then
		eselect compiler-shadow update all
	fi

	elog "You can find additional utility scripts in:"
	elog "  ${EROOT}/usr/lib/llvm/${LLVM_MAJOR}/share/clang"
}

pkg_postrm() {
	if [[ -z ${ROOT} && -f ${EPREFIX}/usr/share/eselect/modules/compiler-shadow.eselect ]] ; then
		eselect compiler-shadow clean all
	fi
}
