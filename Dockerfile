#!/bin/bash
set -eo pipefail

: ${NUM_THREADS:=2}
: ${MLC_BACKEND:=vulkan}

echo "=============================================="
echo "MLC-LLM Build (from source)"
echo "Backend: ${MLC_BACKEND}"
echo "Threads: ${NUM_THREADS}"
echo "=============================================="

cd /workspace

# Safety check
test -f CMakeLists.txt

# -----------------------------------------------------------------------------
# Configure
# -----------------------------------------------------------------------------
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

echo "=== CMake configure ==="
cmake .. -G Ninja

echo "=== Build ==="
ninja -j ${NUM_THREADS}

cd ..

# -----------------------------------------------------------------------------
# Python install
# -----------------------------------------------------------------------------
cd python
pip install -e . --no-deps
cd ..

echo "=== Build completed successfully ==="
mlc_llm chat -h
