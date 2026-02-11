# Filename: Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TVM_HOME=/opt/tvm
ENV LD_LIBRARY_PATH=$TVM_HOME/build:$LD_LIBRARY_PATH
ENV PYTHONPATH=$TVM_HOME/python

# Install core dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-dev python3-pip \
    llvm-15-dev libxml2-dev libedit-dev libncurses5-dev clang-15 \
    curl wget && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# FIXED: Full URL for Apache TVM (TVM Unity)
RUN git clone --recursive https://github.com/apache/tvm.git tvm && \
    cd tvm && mkdir build && cd build && \
    cp ../cmake/config.cmake . && \
    echo "set(USE_LLVM \"llvm-config-15 --ignore-libllvm --link-static\")" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake && \
    echo "set(USE_CUDA OFF)" >> config.cmake && \
    cmake .. && make -j$(nproc) && \
    # Properly install python bindings to avoid FFI errors
    cd ../python && pip3 install -e .

# Install dependencies for MLC-LLM
RUN pip3 install --upgrade pip setuptools wheel \
    numpy decorator scipy attrs tornado psutil

# FIXED: Full URL for MLC-LLM repository
RUN git clone --recursive 
