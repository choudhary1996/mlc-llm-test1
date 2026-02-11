FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/venv/bin:/root/.cargo/bin:${PATH}"

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
    python3-venv \
    llvm-dev \
    clang \
    cmake \
    rustc \
    cargo \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Create Python virtual environment (REQUIRED)
# -------------------------------------------------
RUN python3 -m venv /opt/venv

# Upgrade pip inside venv
RUN pip install --upgrade pip

# Install Python build dependencies
RUN pip install \
    numpy scipy psutil decorator attrs cloudpickle wheel

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
# Install Python package inside venv
# -------------------------------------------------
RUN pip install -e python

# -------------------------------------------------
# Runtime environment variables
# -------------------------------------------------
ENV TVM_HOME=/opt/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/opt/mlc-llm/python:/opt/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/opt/mlc-llm/build:/opt/mlc-llm/3rdparty/tvm/build

WORKDIR /workspace
