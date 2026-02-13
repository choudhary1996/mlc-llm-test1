# =============================================================================
# MLC-LLM Standalone Docker Image
# Build from source — repo baked into image
# =============================================================================

ARG BASE_IMAGE=ubuntu:22.04

# -----------------------------------------------------------------------------
# Base system + build dependencies
# -----------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.10

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
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    rustc \
    cargo \
    libvulkan-dev \
    libvulkan1 \
    vulkan-tools \
    glslang-tools \
    spirv-tools \
    spirv-headers \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install "cmake>=3.24" ninja

# -----------------------------------------------------------------------------
# Python + runtime dependencies
# -----------------------------------------------------------------------------
FROM base AS dev

RUN pip install \
    datasets fastapi "ml_dtypes>=0.5.1" openai pandas \
    prompt_toolkit requests safetensors sentencepiece \
    shortuuid tiktoken tqdm transformers uvicorn \
    pytest black isort pylint mypy

# TVM runtime (required by mlc_llm)
RUN pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# -----------------------------------------------------------------------------
# Final image
# -----------------------------------------------------------------------------
FROM dev AS final

ARG MLC_BACKEND=vulkan
ENV MLC_BACKEND=${MLC_BACKEND}

WORKDIR /workspace

# Copy FULL repo into image (must include submodules)
COPY . /workspace

# -----------------------------------------------------------------------------
# Build script
# -----------------------------------------------------------------------------
COPY build-entrypoint.sh /usr/local/bin/build-entrypoint.sh
RUN chmod +x /usr/local/bin/build-entrypoint.sh

# -----------------------------------------------------------------------------
# Build Vulkan during image build
# -----------------------------------------------------------------------------
ENV NUM_THREADS=2

RUN if [ "$MLC_BACKEND" = "vulkan" ]; then \
      /usr/local/bin/build-entrypoint.sh ; \
    else \
      echo "CUDA build deferred to runtime GPU host."; \
    fi

# -----------------------------------------------------------------------------
# Runtime defaults — NO rebuild on start
# -----------------------------------------------------------------------------
ENTRYPOINT ["mlc_llm"]
CMD ["chat", "-h"]

LABEL org.opencontainers.image.description="MLC-LLM Standalone Build (Vulkan/CUDA)"
