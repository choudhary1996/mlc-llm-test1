#!/bin/bash
set -eo pipefail

: ${NUM_THREADS:=2}
: ${MLC_BACKEND:=vulkan}

echo "=== Build start ==="
echo "Threads: ${NUM_THREADS}"
echo "Backend: ${MLC_BACKEND}"

cd /workspace

test -f CMakeLists.txt

mkdir -p build && cd build

cat > config.cmake <<CMAKECFG
set(TVM_SOURCE_DIR 3rdparty/tvm)
set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(USE_VULKAN ON)
set(USE_CUDA OFF)
CMAKECFG

cmake .. -G Ninja
ninja -j ${NUM_THREADS}
cd ..

cd python
pip install -e . --no-deps
cd ..

echo "=== Build complete ==="
