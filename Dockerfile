# =============================================================================
# MLC-LLM Standalone Docker Image (Fixed)
# =============================================================================

ARG BASE_IMAGE=ubuntu:22.04

# -----------------------------------------------------------------------------
# Base system + build dependencies
# -----------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS base

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ninja-build \
    git \
    curl \
    wget \
    ca-certificates \
    pkg-config \
    python3 \
    python3-dev \
    python3-venv \
    python3-pip \
    rustc \
    cargo \
    libvulkan-dev \
    libvulkan1 \
    vulkan-tools \
    glslang-tools \
    spirv-tools \
    llvm \
    llvm-dev \
    clang \
    ccache \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install "cmake>=3.24" ninja

# -----------------------------------------------------------------------------
# Python runtime deps
# -----------------------------------------------------------------------------
FROM base AS dev

RUN pip install \
    datasets fastapi "ml_dtypes>=0.5.1" openai pandas \
    prompt_toolkit requests safetensors sentencepiece \
    shortuuid tiktoken tqdm transformers uvicorn

RUN pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# -----------------------------------------------------------------------------
# Final image
# -----------------------------------------------------------------------------
FROM dev AS final

ARG MLC_BACKEND=vulkan
ENV MLC_BACKEND=${MLC_BACKEND}

WORKDIR /workspace

COPY . /workspace

COPY build-entrypoint.sh /usr/local/bin/build-entrypoint.sh
RUN chmod +x /usr/local/bin/build-entrypoint.sh

RUN echo "=== Workspace contents ===" \
 && ls -la /workspace \
 && test -f /workspace/CMakeLists.txt

ENV NUM_THREADS=2

RUN if [ "$MLC_BACKEND" = "vulkan" ]; then \
      echo "=== Building Vulkan backend ===" && \
      /usr/local/bin/build-entrypoint.sh ; \
    else \
      echo "CUDA build deferred to runtime GPU host."; \
    fi

ENTRYPOINT ["mlc_llm"]
CMD ["chat", "-h"]

LABEL org.opencontainers.image.description="MLC-LLM Standalone Build (Vulkan/CUDA)"
