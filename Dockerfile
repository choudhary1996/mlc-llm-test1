FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:${PATH}"

# -------------------------------------------------
# Install system basics
# -------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Install Miniconda
# -------------------------------------------------
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh

# -------------------------------------------------
# Create conda environment (MATCHES YOUR CI)
# -------------------------------------------------
RUN conda create -y -n mlc-chat-venv -c conda-forge \
    python=3.13 \
    "cmake>=3.24" \
    rust \
    git \
    numpy scipy psutil decorator attrs cloudpickle

ENV PATH="/opt/conda/envs/mlc-chat-venv/bin:${PATH}"

# -------------------------------------------------
# Clone MLC-LLM
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
# Install Python package
# -------------------------------------------------
RUN pip install -e python

# -------------------------------------------------
# Runtime environment
# -------------------------------------------------
ENV TVM_HOME=/opt/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/opt/mlc-llm/python:/opt/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/opt/mlc-llm/build:/opt/mlc-llm/3rdparty/tvm/build

WORKDIR /workspace
