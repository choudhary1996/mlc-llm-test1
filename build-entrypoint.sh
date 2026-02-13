#!/bin/bash
set -eo pipefail

: ${NUM_THREADS:=$(nproc)}
: ${MLC_BACKEND:=vulkan}

echo "=============================================="
echo "MLC-LLM Build (from source)"
echo "Backend: ${MLC_BACKEND}"
echo "=============================================="

cd /workspace

if [[ ! -f CMakeLists.txt ]]; then
  echo "ERROR: Repo not found inside image."
  echo "Rebuild image ensuring source is copied."
  exit 1
fi

# -----------------------------------------------------------------------------
# Configure build
# -----------------------------------------------------------------------------
mkdir -p build && cd build

cat > config.cmake <<CMAKECFG
set(TVM_SOURCE_DIR 3rdparty/tvm)
set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(USE_CUDA OFF)
set(USE_VULKAN ON)
CMAKECFG

if [[ ${MLC_BACKEND} == "cuda" ]]; then
  echo "set(USE_CUDA ON)" >> config.cmake
  echo "set(USE_CUBLAS ON)" >> config.cmake
  echo "set(USE_CUTLASS ON)" >> config.cmake
fi

cmake .. -G Ninja
ninja -j ${NUM_THREADS}
cd ..

# -----------------------------------------------------------------------------
# Install Python package
# -----------------------------------------------------------------------------
cd python
pip install -e . --no-deps
cd ..

echo ""
echo "Build complete."
mlc_llm chat -h
