# -------------------------------------------------
# MLC-LLM CPU Build Dockerfile (CI Stable)
# -------------------------------------------------

FROM ubuntu:22.04

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
    llvm-15 \
    llvm-15-dev \
    clang-15 \
    libxml2-dev \
    libedit-dev \
    libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Install CMake >= 3.24 (Ubuntu default is too old)
# -------------------------------------------------
RUN pip3 install --no-cache-dir cmake

# -------------------------------------------------
# Install Rust (Required for tokenizer build)
# -------------------------------------------------
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# -------------------------------------------------
# Clone MLC-LLM with submodules (includes TVM runtime)
# -------------------------------------------------
WORKDIR /opt
RUN git clone --recursive --depth 1 https://github.com/mlc-ai/mlc-llm.git

WORKDIR /opt/mlc-llm

# -------------------------------------------------
# Configure and build (CPU-only for CI stability)
# -------------------------------------------------
RUN mkdir -p build && cd build && \
    python3 ../cmake/gen_cmake_config.py --use-cuda=OFF && \
    cmake .. && \
    make -j4

# -------------------------------------------------
# Install Python package
# -------------------------------------------------
WORKDIR /opt/mlc-llm/python
RUN pip3 install --no-cache-dir -e .

# -------------------------------------------------
# Validate installation (CI safety check)
# -------------------------------------------------
RUN ls -l /opt/mlc-llm/build && \
    python3 -c "import mlc_llm; print('MLC installed at:', mlc_llm.__file__)"

WORKDIR /workspace
