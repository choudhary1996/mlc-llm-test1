# Filename: Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TVM_HOME=/opt/tvm
ENV PYTHONPATH=${TVM_HOME}/python

# Install core dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-dev python3-pip \
    llvm-15-dev libxml2-dev libedit-dev libncurses5-dev clang-15 \
    curl wget && rm -rf /var/lib/apt/lists/*

# Setup workspace
WORKDIR /opt

# FIXED: Use the official Apache TVM repository
# MLC LLM requires TVM Unity, which is built from the main Apache TVM source
RUN git clone --recursive https://github.com/apache/tvm.git tvm && \
    cd tvm && mkdir build && cd build && \
    cp ../cmake/config.cmake . && \
    # Standard MLC build flags
    echo "set(USE_LLVM \"llvm-config-15 --ignore-libllvm --link-static\")" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake && \
    echo "set(USE_CUDA OFF)" >> config.cmake && \
    cmake .. && make -j$(nproc)

# Install Python requirements for MLC-LLM
RUN pip3 install --upgrade pip setuptools wheel \
    numpy decorator scipy attrs tornado psutil

# Clone MLC-LLM source for building the package later
RUN git clone --recursive https://github.com/mlc-ai/mlc-llm.git /opt/mlc-llm

WORKDIR /workspace

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash"]
