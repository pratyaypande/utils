#!/bin/bash

# echo Check the script and remove this line...
echo -------- Checking if GNU Make exists: $(which make 2>/dev/null || echo No... Bailing since further builds will fail. && exit 1)

sudo dnf install bison icu libicu-devel m4 flex zlib
SB_DIR=/home/pratyay
INSTALL_DIR=$SB_DIR/.local
LOG_DIR=$SB_DIR/.logs

mkdir -p $SB_DIR $INSTALL_DIR $LOG_DIR
cd $SB_DIR

export parallel_compile_jobs_num=$(nproc)
export parallel_link_jobs_num=$(expr $parallel_compile_job_num / 8)

echo ---- Setting up clang ----

echo -------- Cloning llvm ...
rm -rf llvm-src
git clone --depth 1 --branch llvmorg-22.1.8 git@github.com:llvm/llvm-project.git llvm-src
cd llvm-src
	
echo -------- Configuring LLVM. Projects: clang and lld. This will take almost 5 minutes...
# Use GNU Make as it will be there in 
cmake -G 'Ninja' -B $PWD/build/Release -S $PWD/llvm                      \
	-DCMAKE_BUILD_TYPE=Release                                           \
	-DCMAKE_C_COMPILER=$(which gcc)                                      \
	-DCMAKE_CXX_COMPILER=$(which g++)                                    \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                   \
	-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/llvm                             \
	-DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra;llvm-lsp-server" \
	-DLLVM_ENABLE_RUNTIMES="openmp"                                      \
	-DLLVM_ENABLE_ASSERTIONS=OFF                                         \
	-DLLVM_ENABLE_LTO=ON                                                 \
	-DLLVM_ENABLE_PIC=ON                                                 \
	-DBUILD_SHARED_LIBS=ON                                               \
	-DLLVM_TARGETS_TO_BUILD="X86"                                 \
	-DLLVM_PARALLEL_COMPILE_JOBS=$parallel_compile_job_num               \
	-DLLVM_PARALLEL_LINK_JOBS=$parallel_link_jobs_num                    \
	-DLLVM_OPTIMIZED_TABLEGEN=TRUE                                       \
	2>&1 | tee $LOG_DIR/cmake-configure-llvm.log

echo -------- Compiling LLVM: clang and lld. This will take almost 4 hours ...
cmake --build $PWD/build/Release --parallel $parallel_compile_job_num 2>&1 | tee $LOG_DIR/cmake-build-llvm.log
	
echo -------- Installing clang and required tools
cmake --install $PWD/build/Release 2>&1 > $LOG_DIR/cmake-install-llvm.log
	
cd $SB_DIR
echo ---- Done installing clang
exit

echo ---- Setting up ninja

echo -------- Cloning ninja source code ... 
rm -rf ninja-src
git clone https://github.com/ninja-build/ninja.git ninja-src 2>&1 > $LOG_DIR/clone-ninja.log
cd ninja-src
git checkout v1.13.2

echo -------- Configuring ninja
cmake -B $PWD/build                           \
	-DCMAKE_BUILD_TYPE=Release                \
	-DCMAKE_C_COMPILER=$(which clang)         \
	-DCMAKE_CXX_COMPILER=$(which clang++)     \
	-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/ninja \
	2>&1 > $LOG_DIR/configure-ninja.log

echo -------- Compiling ninja
cmake --build $PWD/build --parallel 160 2>&1 > $LOG_DIR/compile-ninja.log

echo -------- Installing ninja
cmake --install $PWD/build

echo -------- Ninja is installed. Re-trigger this script to update env and install others
cd $SB_DIR
exit
echo -------- Fetching gettext 0.24
wget https://ftp.gnu.org/pub/gnu/gettext/gettext-0.24.tar.gz
tar -xf gettext-0.24.tar.gz
cd gettext-0.24
CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" \
			./configure --prefix=$INSTALL_DIR/gettext \
			--enable-shared \
			--enable-pic
	
CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" make install

cd $SB_DIR

echo ---- Setting up neovim
echo -------- Cloning neovim ...
rm -rf nvim-src
git clone --depth 1 --branch v0.12.5 git@github.com:neovim/neovim.git nvim-src
cd nvim-src

echo -------- Configuring neovim
CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" make \
	CMAKE_EXTRA_FLAGS="-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/neovim" \
	2>&1 > $LOG_DIR/configure-neovim.log

echo -------- Compiling neovim
CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" make install 2>&1 > $LOG_DIR/compile-neovim.log

cd $SB_DIR

# Installation of liblz4
git clone https://github.com/lz4/lz4.git lz4-src
cd lz4-src
git checkout v1.10.0
make -j$(nproc) CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" PREFIX=$INSTALL_DIR/lz4
make -j$(nproc) CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" PREFIX=$INSTALL_DIR/lz4 install

cd $SB_DIR

# Installation of zstd

git clone https://github.com/facebook/zstd.git zstd-src
cd zstd-src
git checkout v1.5.7

cmake -B build -S build/cmake -G Ninja -DCMAKE_C_COMPILER=$(which clang) -DCMAKE_CXX_COMPILER=$(which clang++) -DCMAKE_BUILD_TYPE="Release" -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/zstd" -DCMAKE_C_FLAGS="-O3 -mtune=znver1" -DCMAKE_CXX_FLAGS="-O3 -mtune=znver1"
cmake --build build --parallel -j$(nproc)
cmake --install build

cd $SB_DIR

# Installation of postgresql

wget https://ftp.postgresql.org/pub/source/v17.5/postgresql-17.5.tar.gz
tar -xf postgresql-17.5.tar.gz
cd postgresql-17.5

CC=$(which clang) CFLAGS="-O3 -mtune=znver1" CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" ./configure --prefix=$INSTALL_DIR/postgresql --with-llvm --without-readline --with-openssl --with-lz4

make -j$(nproc) all
make -j$(nproc) check 
make -j$(nproc) install

cd $SB_DIR

git clone https://github.com/timescale/timescaledb timescaledb-src
cd timescaledb-src
git checkout 2.20.3
CC=$(which clang) CXX=$(which clang) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" ./bootstrap --install-prefix=$INSTALL_DIR/timescaledb -G Ninja
cmake --build ./build --parallel $parallel_compile_job_num
cmake --install ./build

cd $SB_DIR

# Installation of boost libraries
wget https://archives.boost.io/release/1.84.0/source/boost_1_84_0.tar.gz
tar -xf boost_1_84_0.tar.gz
cd boost_1_84_0/
CC=$(which clang) CXX=$(which clang++) CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" ./bootstrap.sh --prefix=$INSTALL_DIR/boost-b2

# CC=clang CXX=clang CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" ./b2 --prefix=$INSTALL_DIR/boost toolset=clang variant=release link=shared threading=multi --cmakedir=$INSTALL_DIR/boost/cmake
CC=clang CXX=clang++ CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" ./b2 --prefix=$INSTALL_DIR/boost toolset=clang variant=release link=shared threading=multi --cmakedir=$INSTALL_DIR/boost/cmake --with-system
CC=clang CXX=clang++ CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" ./b2 --prefix=$INSTALL_DIR/boost toolset=clang variant=release link=shared threading=multi --cmakedir=$INSTALL_DIR/boost/cmake --with-system build
CC=clang CXX=clang++ CXXFLAGS="-O3 -mtune=znver1" CFLAGS="-O3 -mtune=znver1" ./b2 --prefix=$INSTALL_DIR/boost toolset=clang variant=release link=shared threading=multi --cmakedir=$INSTALL_DIR/boost/cmake --with-system install

cd $SB_DIR

# Installation of TBB
git clone git@github.com:uxlfoundation/oneTBB.git
cd oneTBB
git checkout v2021.13.0
cmake -B build -S . -G Ninja -DCMAKE_C_COMPILER=$(which clang) -DCMAKE_CXX_COMPILER=$(which clang++) -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/tbb -DCMAKE_C_FLAGS="-O3 -mtune=znver1" -DCMAKE_CXX_FLAGS="-O3 -mtune=znver1"
cmake --build build --parallel $parallel_compile_job_num
cmake --install build 
