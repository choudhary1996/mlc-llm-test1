# Filename: Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TVM_HOME=/opt/tvm
ENV PYTHONPATH=$TVM_HOME/python:${PYTHONPATH}

# Install core dependencies for both Dev and Build
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-dev python3-pip \
    llvm-15-dev libxml2-dev libedit-dev libncurses5-dev clang-15 \
    curl wget && rm -rf /var/lib/apt/lists/*

# Build TVM Unity (MLC Requirement) from source
WORKDIR /opt
RUN git clone --recursive https://github.com tvm && \
    cd tvm && mkdir build && cd build && \
    cp ../cmake/config.cmake . && \
    echo "set(USE_LLVM \"llvm-config-15 --ignore-libllvm --link-static\")" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake && \
    cmake .. && make -j$(nproc)

# Install Python requirements for MLC-LLM
RUN pip3 install --upgrade pip setuptools wheel \
    numpy decorator scipy attrs tornado psutil

# Setup workspace
WORKDIR /workspace

# ENTRYPOINT allows the image to act as a build tool (non-interactive)
# while remaining accessible for interactive shells
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash"]
