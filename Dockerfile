# -------------------------------------------------
# MLC-LLM Runtime Image (No Compilation)
# -------------------------------------------------

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------
# Install minimal runtime dependencies
# -------------------------------------------------
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libstdc++6 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Set working directory
# -------------------------------------------------
WORKDIR /opt/mlc-llm

# -------------------------------------------------
# Copy prebuilt artifacts from CI
# These MUST exist in build context
# -------------------------------------------------
COPY build ./build
COPY 3rdparty/tvm/build ./3rdparty/tvm/build
COPY python ./python

# -------------------------------------------------
# Install Python package (CLI + bindings)
# -------------------------------------------------
RUN pip3 install --break-system-packages -e python

# -------------------------------------------------
# Runtime environment variables
# -------------------------------------------------
ENV TVM_HOME=/opt/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/opt/mlc-llm/python:/opt/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/opt/mlc-llm/build:/opt/mlc-llm/3rdparty/tvm/build

WORKDIR /workspace
