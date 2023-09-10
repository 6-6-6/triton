# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib prefix rust-toolchain toolchain-funcs verify-sig multilib-minimal

MY_P="rust-${PV}"
MY_ABI="aarch64-apple-darwin"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"
SRC_URI="
	https://static.rust-lang.org/dist/rust-${PV}-${MY_ABI}.pkg
	https://static.rust-lang.org/dist/rust-${PV}-${MY_ABI}.pkg.asc
	rust-src? (
		https://static.rust-lang.org/dist/rustc-${PV}-src.tar.gz
		https://static.rust-lang.org/dist/rustc-${PV}-src.tar.gz.asc
	)
"

LICENSE="|| ( MIT Apache-2.0 ) BSD BSD-1 BSD-2 BSD-4 UoI-NCSA"
SLOT="stable"
KEYWORDS="arm64-macos"
IUSE="clippy cpu_flags_x86_sse2 doc prefix rust-analyzer rust-src rustfmt"

DEPEND=""

RDEPEND="
	>=app-eselect/eselect-rust-20190311
	dev-libs/openssl
	sys-apps/lsb-release
"

BDEPEND="
	verify-sig? ( sec-keys/openpgp-keys-rust )
"

REQUIRED_USE="x86? ( cpu_flags_x86_sse2 )"

QA_PREBUILT="
	opt/${P}/bin/.*
	opt/${P}/lib/.*.so
	opt/${P}/libexec/.*
	opt/${P}/lib/rustlib/.*/bin/.*
	opt/${P}/lib/rustlib/.*/lib/.*
"

# An rmeta file is custom binary format that contains the metadata for the crate.
# rmeta files do not support linking, since they do not contain compiled object files.
# so we can safely silence the warning for this QA check.
QA_EXECSTACK="opt/${P}/lib/rustlib/*/lib*.rlib:lib.rmeta"

VERIFY_SIG_OPENPGP_KEY_PATH="${BROOT}/usr/share/openpgp-keys/rust.asc"

pkg_pretend() {
	if [[ "$(tc-is-softfloat)" != "no" ]] && [[ ${CHOST} == armv7* ]]; then
		die "${CHOST} is not supported by upstream Rust. You must use a hard float version."
	fi
}

src_unpack() {
	rust_abi=${MY_ABI}
	# sadly rust-src tarball does not have corresponding .asc file
	# so do partial verification
	if use verify-sig; then
		for f in ${A}; do
			if [[ -f ${DISTDIR}/${f}.asc ]]; then
				verify-sig_verify_detached "${DISTDIR}/${f}" "${DISTDIR}/${f}.asc"
			fi
		done
	fi

	default_src_unpack

	/usr/sbin/pkgutil --expand "${DISTDIR}"/rust-${PV}-${rust_abi}.pkg ${S}
}

patchelf_for_bin() {
	local filetype=$(file -b ${1})
	if [[ ${filetype} == *ELF*interpreter* ]]; then
		einfo "${1}'s interpreter changed"
		patchelf ${1} --set-interpreter ${2} || die
	elif [[ ${filetype} == *script* ]]; then
		hprefixify ${1}
	fi
}

multilib_src_install() {
	if multilib_is_native_abi; then

	# start native abi install
	pushd "${S}" >/dev/null || die
	
	for comp in rustc cargo rust-std;do
		./"${comp}".pkg/Scripts/install.sh \
			--disable-verify \
			--prefix="${ED}/opt/${P}" \
			--mandir="${ED}/opt/${P}/man" \
			--disable-ldconfig \
			--verbose || die
	done

	if use prefix; then
		local interpreter=$(patchelf --print-interpreter ${EPREFIX}/bin/bash)
		ebegin "Changing interpreter to ${interpreter} for Gentoo prefix at ${ED}/opt/${P}/bin"
		find "${ED}/opt/${P}/bin" -type f -print0 | \
			while IFS=  read -r -d '' filename; do
				patchelf_for_bin ${filename} ${interpreter} \; || die
			done
		eend $?
	fi

	local symlinks=(
		cargo
		rustc
		rustdoc
		rust-gdb
		rust-gdbgui
		rust-lldb
	)

	use clippy && symlinks+=( clippy-driver cargo-clippy )
	use rustfmt && symlinks+=( rustfmt cargo-fmt )
	use rust-analyzer && symlinks+=( rust-analyzer )

	einfo "installing eselect-rust symlinks and paths"
	local i
	for i in "${symlinks[@]}"; do
		# we need realpath on /usr/bin/* symlink return version-appended binary path.
		# so /usr/bin/rustc should point to /opt/rust-bin-<ver>/bin/rustc-<ver>
		local ver_i="${i}-bin-macos-${PV}"
		ln -v "${ED}/opt/${P}/bin/${i}" "${ED}/opt/${P}/bin/${ver_i}" || die
		dosym "../../opt/${P}/bin/${ver_i}" "/usr/bin/${ver_i}"
	done

	# symlinks to switch components to active rust in eselect
	dosym "../../../opt/${P}/lib" "/usr/lib/rust/lib-bin-macos-${PV}"
	dosym "../../../opt/${P}/man" "/usr/lib/rust/man-bin-macos-${PV}"
	dosym "../../opt/${P}/lib/rustlib" "/usr/lib/rustlib-bin-macos-${PV}"
	dosym "../../../opt/${P}/share/doc/rust" "/usr/share/doc/${P}"

	# make all capital underscored variable
	local CARGO_TRIPLET="$(rust_abi)"
	CARGO_TRIPLET="${CARGO_TRIPLET//-/_}"
	CARGO_TRIPLET="${CARGO_TRIPLET^^}"
	cat <<-_EOF_ > "${T}/50${P}"
	LDPATH="${EPREFIX}/usr/lib/rust/lib"
	MANPATH="${EPREFIX}/usr/lib/rust/man"
	$(usev elibc_musl "CARGO_TARGET_${CARGO_TRIPLET}_RUSTFLAGS=\"-C target-feature=-crt-static\"")
	_EOF_
	doenvd "${T}/50${P}"

	# note: eselect-rust adds EROOT to all paths below
	cat <<-_EOF_ > "${T}/provider-${P}"
	/usr/bin/cargo
	/usr/bin/rustdoc
	/usr/bin/rust-gdb
	/usr/bin/rust-gdbgui
	/usr/bin/rust-lldb
	/usr/lib/rustlib
	/usr/lib/rust/lib
	/usr/lib/rust/man
	/usr/share/doc/rust
	_EOF_

	if use clippy; then
		echo /usr/bin/clippy-driver >> "${T}/provider-${P}"
		echo /usr/bin/cargo-clippy >> "${T}/provider-${P}"
	fi
	if use rustfmt; then
		echo /usr/bin/rustfmt >> "${T}/provider-${P}"
		echo /usr/bin/cargo-fmt >> "${T}/provider-${P}"
	fi
	if use rust-analyzer; then
		echo /usr/bin/rust-analyzer >> "${T}/provider-${P}"
	fi

	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
	popd >/dev/null || die
	#end native abi install

	else
		local rust_target
		rust_target="$(rust_abi $(get_abi_CHOST ${v##*.}))"
		dodir "/opt/${P}/lib/rustlib"
		cp -vr "${WORKDIR}/rust-${PV}-${rust_target}/rust-std-${rust_target}/lib/rustlib/${rust_target}"\
			"${ED}/opt/${P}/lib/rustlib" || die
	fi

	# BUG: installs x86_64 binary on other arches
	rm -f "${ED}/opt/${P}/lib/rustlib/"*/bin/rust-llvm-dwp || die
}

pkg_postinst() {
	eselect rust update

	elog "Rust installs a helper script for calling GDB now,"
	elog "for your convenience it is installed under /usr/bin/rust-gdb-bin-macos-${PV}."

	if has_version app-editors/emacs; then
		elog "install app-emacs/rust-mode to get emacs support for rust."
	fi

	if has_version app-editors/gvim || has_version app-editors/vim; then
		elog "install app-vim/rust-vim to get vim support for rust."
	fi
}

pkg_postrm() {
	eselect rust cleanup
}
