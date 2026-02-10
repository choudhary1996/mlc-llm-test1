# =========================================================
# Multipurpose Dev + Build Image (Production Grade)
# =========================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# ---------------------------------------------------------
# System dependencies
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
# Install Miniforge (No ToS issues)
# ---------------------------------------------------------
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O miniforge.sh && \
    bash miniforge.sh -b -p $CONDA_DIR && \
    rm miniforge.sh && \
    conda clean -afy

SHELL ["bash", "-l", "-c"]

# ---------------------------------------------------------
# Create environment
# ---------------------------------------------------------
RUN conda create -y -n mlc-chat-venv \
    python=3.12 \
    "cmake>=3.24" \
    rust \
    git \
    && conda clean -afy

RUN echo "conda activate mlc-chat-venv" >> ~/.bashrc

WORKDIR /workspace
COPY . /workspace

# ---------------------------------------------------------
# Build script (FIXED)
# ---------------------------------------------------------
RUN cat <<'EOF' > /usr/local/bin/build-mlc
#!/usr/bin/env bash
set -e

conda activate mlc-chat-venv

echo "=== Generate config ==="
mkdir -p build
cd build
printf "\nn\nn\nn\nn\nn\n" | python ../cmake/gen_cmake_config.py

echo "=== Build mlc_llm ==="
cmake ..
cmake --build . --parallel

echo "=== Build TVM ==="
cd ../3rdparty/tvm
mkdir -p build
cd build
cmake ..
cmake --build . --parallel

echo "=== Install Python bindings ==="
cd ../python
pip install -e .

cd /workspace/python
pip install -e . --no-deps

pip install psutil numpy decorator attrs cloudpickle

echo "=== Build complete ==="
EOF

RUN chmod +x /usr/local/bin/build-mlc

# ---------------------------------------------------------
# Package script (FIXED)
# ---------------------------------------------------------
RUN cat <<'EOF' > /usr/local/bin/package-mlc
#!/usr/bin/env bash
set -e

mkdir -p /artifacts

cp -r /workspace/build /artifacts/
cp -r /workspace/3rdparty/tvm/build /artifacts/

echo "Artifacts stored in /artifacts"
EOF

RUN chmod +x /usr/local/bin/package-mlc

CMD ["bash"]
