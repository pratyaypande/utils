#!/bin/bash

# echo Check the script and remove this line...
# exit 1 
SB_DIR=$H
INSTALL_DIR=$SB_DIR/.local
LOG_DIR=$SB_DIR/.logs

mkdir -p $SB_DIR $INSTALL_DIR $LOG_DIR
cd $SB_DIR

export parallel_compile_jobs_num=$(nproc)
export parallel_link_jobs_num=$(expr $parallel_compile_job_num / 8)

cd llvm-src

echo -------- Configuring LLVM. Projects: clang and lld. This will take almost 5 minutes...
# Use GNU Make as it will be there in 
cmake -G 'Ninja' -B $PWD/build/Release -S $PWD/llvm    \
	-DCMAKE_BUILD_TYPE=Release                                  \
	-DCMAKE_C_COMPILER=$(which gcc)                             \
	-DCMAKE_CXX_COMPILER=$(which g++)                           \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON                          \
	-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/llvm                    \
	-DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra"        \
	-DLLVM_ENABLE_RUNTIMES="openmp"                             \
	-DLLVM_ENABLE_ASSERTIONS=OFF                                \
	-DLLVM_ENABLE_LTO=ON                                        \
	-DLLVM_ENABLE_PIC=ON                                        \
	-DBUILD_SHARED_LIBS=ON                                      \
	-DLLVM_TARGETS_TO_BUILD="AMDGPU;X86"                        \
	-DLLVM_PARALLEL_COMPILE_JOBS=$parallel_compile_job_num      \
	-DLLVM_PARALLEL_LINK_JOBS=$parallel_link_jobs_num           \
	-DLLVM_OPTIMIZED_TABLEGEN=TRUE                              \
	2>&1 | tee $LOG_DIR/cmake-configure-llvm.log
	
echo -------- Compiling LLVM: clang and lld. This will take almost 4 hours ...
cmake --build $PWD/build/Release --parallel $parallel_compile_job_num 2>&1 | tee $LOG_DIR/cmake-build-llvm.log
	
echo -------- Installing clang and required tools
cmake --install $PWD/build/Release 2>&1 > $LOG_DIR/cmake-install-llvm.log
	
cd $SB_DIR
echo ---- Done installing clang

