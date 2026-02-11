FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TVM_HOME=/opt/tvm
# Ensure the compiled library is discoverable by the linker
ENV LD_LIBRARY_PATH=$TVM_HOME/build:$LD_LIBRARY_PATH
ENV PYTHONPATH=$TVM_HOME/python

RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-dev python3-pip \
    llvm-15-dev libxml2-dev libedit-dev libncurses5-dev clang-15 \
    curl wget && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Build TVM with CPU-only flags
RUN git clone --recursive https://github.com tvm && \
    cd tvm && mkdir build && cd build && \
    cp ../cmake/config.cmake . && \
    echo "set(USE_LLVM \"llvm-config-15 --ignore-libllvm --link-static\")" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake && \
    echo "set(USE_CUDA OFF)" >> config.cmake && \
    echo "set(USE_VULKAN OFF)" >> config.cmake && \
    echo "set(USE_OPENCL OFF)" >> config.cmake && \
    cmake .. && make -j$(nproc) && \
    # This step fixes the tvm_ffi issue
    cd ../python && pip3 install --underline-global-env -e .

RUN pip3 install --upgrade pip setuptools wheel \
    numpy decorator scipy attrs tornado psutil

# Prepare MLC-LLM source
RUN git clone --recursive https://github.com /opt/mlc-llm

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash"]
