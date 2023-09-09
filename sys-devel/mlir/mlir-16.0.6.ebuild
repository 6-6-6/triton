# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit cmake-multilib flag-o-matic llvm llvm.org python-any-r1 \
	toolchain-funcs

DESCRIPTION="Multi-Level Intermediate Representation "
HOMEPAGE="https://mlir.llvm.org"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT )"
SLOT="${LLVM_MAJOR}/${LLVM_SOABI}"
KEYWORDS="arm64-macos"
IUSE="+clang +static-libs test"
REQUIRED_USE="test? ( clang )"
RESTRICT="!test? ( test )"

DEPEND="
	${RDEPEND}
	sys-devel/llvm:${LLVM_MAJOR}
"
BDEPEND="
	clang? (
		sys-devel/clang:${LLVM_MAJOR}
	)
	!test? (
		${PYTHON_DEPS}
	)
	test? (
		>=dev-util/cmake-3.16
		sys-devel/gdb[python]
		$(python_gen_any_dep 'dev-python/lit[${PYTHON_USEDEP}]')
	)
"

LLVM_COMPONENTS=( mlir cmake )
LLVM_USE_TARGETS=llvm
llvm.org_set_globals

python_check_deps() {
	use test || return 0
	python_has_version "dev-python/lit[${PYTHON_USEDEP}]"
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
					# tools
					mlir-*)
						;;
					# static libraries
					mlir*|findAllSymbols)
						continue
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
		mlir-tblgen
		mlir-headers
		mlir-libraries
		distribution
		MLIRAMDGPUDialect
		MLIRAMDGPUToROCDL
		MLIRAMXDialect
		MLIRAMXToLLVMIRTranslation
		MLIRAMXTransforms
		MLIRAffineAnalysis
		MLIRAffineDialect
		MLIRAffineToStandard
		MLIRAffineTransformOps
		MLIRAffineTransforms
		MLIRAffineUtils
		MLIRAnalysis
		MLIRArithAttrToLLVMConversion
		MLIRArithDialect
		MLIRArithToLLVM
		MLIRArithToSPIRV
		MLIRArithTransforms
		MLIRArithUtils
		MLIRArmNeon2dToIntr
		MLIRArmNeonDialect
		MLIRArmNeonToLLVMIRTranslation
		MLIRArmSVEDialect
		MLIRArmSVEToLLVMIRTranslation
		MLIRArmSVETransforms
		MLIRAsmParser
		MLIRAsyncDialect
		MLIRAsyncToLLVM
		MLIRAsyncTransforms
		MLIRBufferizationDialect
		MLIRBufferizationToMemRef
		MLIRBufferizationTransformOps
		MLIRBufferizationTransforms
		MLIRBytecodeReader
		MLIRBytecodeWriter
		MLIRCAPIAsync
		MLIRCAPIControlFlow
		MLIRCAPIConversion
		MLIRCAPIDebug
		MLIRCAPIExecutionEngine
		MLIRCAPIFunc
		MLIRCAPIGPU
		MLIRCAPIIR
		MLIRCAPIInterfaces
		MLIRCAPILLVM
		MLIRCAPILinalg
		MLIRCAPIMLProgram
		MLIRCAPIPDL
		MLIRCAPIQuant
		MLIRCAPIRegisterEverything
		MLIRCAPISCF
		MLIRCAPIShape
		MLIRCAPISparseTensor
		MLIRCAPITensor
		MLIRCAPITransformDialect
		MLIRCAPITransforms
		MLIRCallInterfaces
		MLIRCastInterfaces
		MLIRComplexDialect
		MLIRComplexToLLVM
		MLIRComplexToLibm
		MLIRComplexToStandard
		MLIRControlFlowDialect
		MLIRControlFlowInterfaces
		MLIRControlFlowToLLVM
		MLIRControlFlowToSPIRV
		MLIRCopyOpInterface
		MLIRDLTIDialect
		MLIRDataLayoutInterfaces
		MLIRDerivedAttributeOpInterface
		MLIRDestinationStyleOpInterface
		MLIRDialect
		MLIRDialectUtils
		MLIREmitCDialect
		MLIRExecutionEngine
		MLIRExecutionEngineUtils
		MLIRFromLLVMIRTranslationRegistration
		MLIRFuncDialect
		MLIRFuncToLLVM
		MLIRFuncToSPIRV
		MLIRFuncTransforms
		MLIRGPUOps
		MLIRGPUToGPURuntimeTransforms
		MLIRGPUToNVVMTransforms
		MLIRGPUToROCDLTransforms
		MLIRGPUToSPIRV
		MLIRGPUToVulkanTransforms
		MLIRGPUTransformOps
		MLIRGPUTransforms
		MLIRIR
		MLIRIndexDialect
		MLIRIndexToLLVM
		MLIRInferIntRangeCommon
		MLIRInferIntRangeInterface
		MLIRInferTypeOpInterface
		MLIRJitRunner
		MLIRLLVMCommonConversion
		MLIRLLVMDialect
		MLIRLLVMIRToLLVMTranslation
		MLIRLLVMIRTransforms
		MLIRLLVMToLLVMIRTranslation
		MLIRLinalgAnalysis
		MLIRLinalgDialect
		MLIRLinalgToLLVM
		MLIRLinalgToStandard
		MLIRLinalgTransformOps
		MLIRLinalgTransforms
		MLIRLinalgUtils
		MLIRLoopLikeInterface
		MLIRLspServerLib
		MLIRLspServerSupportLib
		MLIRMLProgramDialect
		MLIRMaskableOpInterface
		MLIRMaskingOpInterface
		MLIRMathDialect
		MLIRMathToFuncs
		MLIRMathToLLVM
		MLIRMathToLibm
		MLIRMathToSPIRV
		MLIRMathTransforms
		MLIRMemRefDialect
		MLIRMemRefToLLVM
		MLIRMemRefToSPIRV
		MLIRMemRefTransformOps
		MLIRMemRefTransforms
		MLIRMemRefUtils
		MLIRMlirOptMain
		MLIRNVGPUDialect
		MLIRNVGPUToNVVM
		MLIRNVGPUTransforms
		MLIRNVGPUUtils
		MLIRNVVMDialect
		MLIRNVVMToLLVMIRTranslation
		MLIROpenACCDialect
		MLIROpenACCToLLVM
		MLIROpenACCToLLVMIRTranslation
		MLIROpenACCToSCF
		MLIROpenMPDialect
		MLIROpenMPToLLVM
		MLIROpenMPToLLVMIRTranslation
		MLIROptLib
		MLIRPDLDialect
		MLIRPDLInterpDialect
		MLIRPDLLAST
		MLIRPDLLCodeGen
		MLIRPDLLODS
		MLIRPDLToPDLInterp
		MLIRParallelCombiningOpInterface
		MLIRParser
		MLIRPass
		MLIRPresburger
		MLIRQuantDialect
		MLIRQuantUtils
		MLIRROCDLDialect
		MLIRROCDLToLLVMIRTranslation
		MLIRReconcileUnrealizedCasts
		MLIRReduce
		MLIRReduceLib
		MLIRRewrite
		MLIRRuntimeVerifiableOpInterface
		MLIRSCFDialect
		MLIRSCFToControlFlow
		MLIRSCFToGPU
		MLIRSCFToOpenMP
		MLIRSCFToSPIRV
		MLIRSCFTransformOps
		MLIRSCFTransforms
		MLIRSCFUtils
		MLIRSPIRVBinaryUtils
		MLIRSPIRVConversion
		MLIRSPIRVDeserialization
		MLIRSPIRVDialect
		MLIRSPIRVModuleCombiner
		MLIRSPIRVSerialization
		MLIRSPIRVToLLVM
		MLIRSPIRVTransforms
		MLIRSPIRVTranslateRegistration
		MLIRSPIRVUtils
		MLIRShapeDialect
		MLIRShapeOpsTransforms
		MLIRShapeToStandard
		MLIRShapedOpInterfaces
		MLIRSideEffectInterfaces
		MLIRSparseTensorDialect
		MLIRSparseTensorEnums
		MLIRSparseTensorPipelines
		MLIRSparseTensorRuntime
		MLIRSparseTensorTransforms
		MLIRSparseTensorUtils
		MLIRSupport
		MLIRSupportIndentedOstream
		MLIRTableGen
		MLIRTargetCpp
		MLIRTargetLLVMIRExport
		MLIRTargetLLVMIRImport
		MLIRTblgenLib
		MLIRTensorDialect
		MLIRTensorInferTypeOpInterfaceImpl
		MLIRTensorTilingInterfaceImpl
		MLIRTensorToLinalg
		MLIRTensorToSPIRV
		MLIRTensorTransforms
		MLIRTensorUtils
		MLIRTilingInterface
		MLIRToLLVMIRTranslationRegistration
		MLIRTosaDialect
		MLIRTosaToArith
		MLIRTosaToLinalg
		MLIRTosaToSCF
		MLIRTosaToTensor
		MLIRTosaTransforms
		MLIRTransformDialect
		MLIRTransformDialectTransforms
		MLIRTransformDialectUtils
		MLIRTransformUtils
		MLIRTransforms
		MLIRTranslateLib
		MLIRVectorDialect
		MLIRVectorInterfaces
		MLIRVectorToGPU
		MLIRVectorToLLVM
		MLIRVectorToSCF
		MLIRVectorToSPIRV
		MLIRVectorTransformOps
		MLIRVectorTransforms
		MLIRVectorUtils
		MLIRViewLikeInterface
		MLIRX86VectorDialect
		MLIRX86VectorToLLVMIRTranslation
		MLIRX86VectorTransforms
		mlir-cmake-exports
		obj.MLIRCAPIAsync
		obj.MLIRCAPIControlFlow
		obj.MLIRCAPIConversion
		obj.MLIRCAPIDebug
		obj.MLIRCAPIExecutionEngine
		obj.MLIRCAPIFunc
		obj.MLIRCAPIGPU
		obj.MLIRCAPIIR
		obj.MLIRCAPIInterfaces
		obj.MLIRCAPILLVM
		obj.MLIRCAPILinalg
		obj.MLIRCAPIMLProgram
		obj.MLIRCAPIPDL
		obj.MLIRCAPIQuant
		obj.MLIRCAPIRegisterEverything
		obj.MLIRCAPISCF
		obj.MLIRCAPIShape
		obj.MLIRCAPISparseTensor
		obj.MLIRCAPITensor
		obj.MLIRCAPITransformDialect
		obj.MLIRCAPITransforms
	)

	printf "%s${sep}" "${out[@]}"
}

pkg_setup() {
	# Darwin Prefix builds do not have llvm installed yet, so rely on
	# bootstrap-prefix to set the appropriate path vars to LLVM instead
	# of using llvm_pkg_setup.
	if [[ ${CHOST} != *-darwin* ]] || has_version sys-devel/llvm; then
		LLVM_MAX_SLOT=${LLVM_MAJOR} llvm_pkg_setup
	fi
	python-any-r1_pkg_setup

}

test_compiler() {
	$(tc-getCXX) ${CXXFLAGS} ${LDFLAGS} "${@}" -o /dev/null -x c++ - \
		<<<'int main() { return 0; }' &>/dev/null
}

multilib_src_configure() {
	if use clang; then
		local -x CC=${CHOST}-clang
		local -x CXX=${CHOST}-clang++
		strip-unsupported-flags
	fi

	# link to compiler-rt
	local use_compiler_rt=OFF
	[[ $(tc-get-c-rtlib) == compiler-rt ]] && use_compiler_rt=ON

	# bootstrap: cmake is unhappy if compiler can't link to stdlib
	local nolib_flags=( -nodefaultlibs -lc )
	if ! test_compiler; then
		if test_compiler "${nolib_flags[@]}"; then
			local -x LDFLAGS="${LDFLAGS} ${nolib_flags[*]}"
			ewarn "${CXX} seems to lack runtime, trying with ${nolib_flags[*]}"
		fi
	fi

	local libdir=$(get_libdir)
	local mycmakeargs=(
		-DCMAKE_CXX_COMPILER_TARGET="${CHOST}"
		-DPython3_EXECUTABLE="${PYTHON}"
		-DLLVM_INCLUDE_TESTS=OFF
		-DLLVM_LIBDIR_SUFFIX=${libdir#lib}
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}"
		-DCMAKE_INSTALL_MANDIR="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/share/man"
		-DLLVM_DISTRIBUTION_COMPONENTS=$(get_distribution_components)

	)

	if use test; then
		mycmakeargs+=(
			-DLLVM_EXTERNAL_LIT="${EPREFIX}/usr/bin/lit"
			-DLLVM_LIT_ARGS="$(get_lit_flags)"
			-DPython3_EXECUTABLE="${PYTHON}"
		)
	fi
	cmake_src_configure
	multilib_is_native_abi && check_distribution_components
}

multilib_src_compile() {
	cmake_build distribution
}

multilib_src_test() {
	local -x LIT_PRESERVES_TMP=1
	# never tested
	cmake_build check-mlir
}

multilib_src_install() {
	DESTDIR=${D} cmake_build install-distribution
}

