# =========================================================
# Multipurpose Dev + Build Image (Production Grade)
# ToS-safe + CI-safe
# =========================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# ---------------------------------------------------------
# System Dependencies
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    ninja-build \
    curl \
    wget \
    pkg-config \
    libtinfo-dev \
    libxml2-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Install Miniconda
# ---------------------------------------------------------
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    conda clean -afy

SHELL ["bash", "-l", "-c"]

# ---------------------------------------------------------
# 🔧 Configure Conda (Avoid ToS + faster)
# ---------------------------------------------------------
RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

# ---------------------------------------------------------
# Create Environment
# ---------------------------------------------------------
RUN conda create -y -n mlc-chat-venv \
    python=3.12 \
    "cmake>=3.24" \
    rust \
    git \
    && conda clean -afy

RUN echo "conda activate mlc-chat-venv" >> ~/.bashrc

WORKDIR /workspace

# ---------------------------------------------------------
# Copy source
# ---------------------------------------------------------
COPY . /workspace

# ---------------------------------------------------------
# Build script
# ---------------------------------------------------------
RUN echo '#!/usr/bin/env bash\n\
set -e\n\
conda activate mlc-chat-venv\n\
mkdir -p build && cd build\n\
printf "\\nn\\nn\\nn\\nn\\nn\\n" | python ../cmake/gen_cmake_config.py\n\
cmake ..\n\
cmake --build . --parallel\n\
cd ../3rdparty/tvm\n\
mkdir -p build && cd build\n\
cmake ..\n\
cmake --build . --parallel\n\
cd ../python && pip install -e .\n\
cd /workspace/python && pip install -e . --no-deps\n\
pip install psutil numpy decorator attrs cloudpickle\n\
' > /usr/local/bin/build-mlc && chmod +x /usr/local/bin/build-mlc

# ---------------------------------------------------------
# Package script
# ---------------------------------------------------------
RUN echo '#!/usr/bin/env bash\n\
set -e\n\
mkdir -p /artifacts\n\
cp -r /workspace/build /artifacts/\n\
cp -r /workspace/3rdparty/tvm/build /artifacts/\n\
' > /usr/local/bin/package-mlc && chmod +x /usr/local/bin/package-mlc

CMD ["bash"]
