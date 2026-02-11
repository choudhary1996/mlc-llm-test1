FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.cargo/bin:${PATH}"

# -------------------------------------------------
# Install system dependencies
# -------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    ca-certificates \
    python3 \
    python3-dev \
    python3-pip \
    llvm-dev \
    clang \
    cmake \
    rustc \
    cargo \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Install Python deps
# -------------------------------------------------
RUN pip3 install --no-cache-dir \
    numpy scipy psutil decorator attrs cloudpickle

# -------------------------------------------------
# Clone MLC-LLM with submodules
# -------------------------------------------------
WORKDIR /opt
RUN git clone --recursive --depth 1 https://github.com/mlc-ai/mlc-llm.git

WORKDIR /opt/mlc-llm

# -------------------------------------------------
# Build TVM (CPU only)
# -------------------------------------------------
RUN cd 3rdparty/tvm && \
    mkdir -p build && cd build && \
    cmake .. \
      -DUSE_CUDA=OFF \
      -DUSE_CUBLAS=OFF \
      -DUSE_CUTLASS=OFF \
      -DBUILD_SHARED_LIBS=ON && \
    make -j4

# -------------------------------------------------
# Build MLC-LLM Core
# -------------------------------------------------
RUN mkdir -p build && cd build && \
    cmake .. \
      -DUSE_CUDA=OFF \
      -DUSE_CUBLAS=OFF \
      -DUSE_CUTLASS=OFF \
      -DBUILD_SHARED_LIBS=ON && \
    make -j4

# -------------------------------------------------
# Install Python Package
# -------------------------------------------------
RUN pip3 install -e python

# -------------------------------------------------
# Set runtime environment
# -------------------------------------------------
ENV TVM_HOME=/opt/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/opt/mlc-llm/python:/opt/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/opt/mlc-llm/build:/opt/mlc-llm/3rdparty/tvm/build

WORKDIR /workspace
