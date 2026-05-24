FROM debian:13

ARG TARGETOS
ARG TARGETARCH
ARG CUDA=0
ARG LMS_INSTALL_HOME=/root

ENV HOME="${LMS_INSTALL_HOME}" \
    PATH="${LMS_INSTALL_HOME}/.lmstudio/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        grep \
        libatomic1 \
        libgomp1 \
        mawk \
        tar \
    && if [ "$CUDA" != "1" ]; then \
        apt-get install -y --no-install-recommends \
          libvulkan1 \
          mesa-vulkan-drivers; \
       fi \
    && rm -rf /var/lib/apt/lists/*

COPY install.sh /tmp/install.sh

RUN chmod +x /tmp/install.sh \
    && LMS_FORCE_CUDA12="$CUDA" \
       LMS_TARGET_OS="$TARGETOS" \
       LMS_TARGET_ARCH="$TARGETARCH" \
       LMS_INSTALL_HOME="$HOME" \
       /tmp/install.sh --no-modify-path \
    && rm -f /tmp/install.sh

EXPOSE 1234

ENTRYPOINT ["lms"]
CMD ["--help"]
