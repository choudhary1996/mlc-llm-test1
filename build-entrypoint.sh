#!/bin/bash
set -eo pipefail

: ${NUM_THREADS:=2}
: ${MLC_BACKEND:=vulkan}

echo "=== Build start ==="

cd /workspace
test -f CMakeLists.txt

mkdir -p build && cd build

cat > config.cmake <<CMAKECFG
set(TVM_SOURCE_DIR 3rdparty/tvm)
set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(USE_VULKAN ON)
set(USE_CUDA OFF)
CMAKECFG

if [[ ${MLC_BACKEND} == "cuda" ]]; then
  echo "set(USE_CUDA ON)" >> config.cmake
  echo "set(USE_CUBLAS ON)" >> config.cmake
  echo "set(USE_CUTLASS ON)" >> config.cmake
fi

cmake .. -G Ninja
ninja -j ${NUM_THREADS}

cd ../python
pip install -e . --no-deps

echo "=== Build complete ==="
mlc_llm chat -h
