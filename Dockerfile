FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libstdc++6 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/mlc-llm

COPY build ./build
COPY 3rdparty/tvm/build ./3rdparty/tvm/build
COPY python ./python

RUN pip3 install --break-system-packages -e python

ENV TVM_HOME=/opt/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/opt/mlc-llm/python:/opt/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/opt/mlc-llm/build:/opt/mlc-llm/3rdparty/tvm/build

WORKDIR /workspace
