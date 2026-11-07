ARG FEDORA_VERSION=45
ARG PYTHON_VERSION=3.14
ARG SCANCODE_IO_VERSION=38.2.0
ARG SCANCODE_PLUGINS_VERSION=1.0.1

FROM ghcr.io/nedix/fedora-base-container:${FEDORA_VERSION}

RUN dnf makecache --refresh

ARG PYTHON_VERSION

ARG BUILD_DEPENDENCIES_DNF=" \
    bison \
    bzip2-devel \
    cargo \
    expat-devel \
    file-libs \
    git \
    golang \
    gpgme-devel \
    gzip \
    libarchive-devel \
    libb2-devel \
    libgcab1-devel \
    libgsf-devel \
    lz4-devel \
    make \
    meson \
    p7zip \
    p7zip-plugins \
    python${PYTHON_VERSION%%.*}-devel \
    python${PYTHON_VERSION%%.*}-libs \
    python${PYTHON_VERSION%%.*}-pip \
    rust-devicemapper-devel \
    tar \
    unzip \
    vala \
    wget \
    xz-devel \
    zlib-ng-compat-devel \
"

ARG BUILD_DEPENDENCIES_PIP=" \
    setuptools \
    wheel \
"

RUN dnf install -y  \
        "python${PYTHON_VERSION}" \
        $BUILD_DEPENDENCIES_DNF \
    && ln -s "/usr/bin/python${PYTHON_VERSION%%.*}" /usr/bin/python \
    && pip install $BUILD_DEPENDENCIES_PIP

WORKDIR /build/scancode-plugins/

ARG SCANCODE_PLUGINS_VERSION

RUN case "$(uname -m)" in \
        aarch64) \
            MANYLINUX_ARCHITECTURE="aarch64" \
        ;; x86_64) \
            MANYLINUX_ARCHITECTURE="x86_64" \
        ;; *) echo "Unsupported architecture: $(uname -m)"; exit 1; ;; \
    esac \
    && wget -qO- "https://github.com/aboutcode-org/scancode-plugins/tarball/v${SCANCODE_PLUGINS_VERSION}" \
    | tar -xpzf- --strip-components=1 \
    && cd /build/scancode-plugins/builtins/extractcode_7z-linux \
    && sed -E \
        -e "s|manylinux1_x86_64|manylinux_2_34_${MANYLINUX_ARCHITECTURE}|" \
        -i ./setup.cfg \
    && ln -fs /usr/bin/7z ./src/extractcode_7z/bin/7z \
    && ln -fs /usr/libexec/p7zip/7z.so ./src/extractcode_7z/bin/7z.so \
    && python setup.py release \
    && pip install $(find ./dist/ -name "*.whl") \
    && cd /build/scancode-plugins/builtins/extractcode_libarchive-linux \
    && sed -E \
        -e "s|manylinux1_x86_64|manylinux_2_34_${MANYLINUX_ARCHITECTURE}|" \
        -i ./setup.cfg \
    && ln -fs /usr/lib64/libarchive.so ./src/extractcode_libarchive/lib/libarchive.so \
    && ln -fs /usr/lib64/libb2.so ./src/extractcode_libarchive/lib/libb2-la3511.so.1 \
    && ln -fs /usr/lib64/libbz2.so ./src/extractcode_libarchive/lib/libbz2-la3511.so.1.0 \
    && ln -fs /usr/lib64/libexpat.so ./src/extractcode_libarchive/lib/libexpat-la3511.so.1 \
    && ln -fs /usr/lib64/liblz4.so ./src/extractcode_libarchive/lib/liblz4-la3511.so.1 \
    && ln -fs /usr/lib64/liblzma.so ./src/extractcode_libarchive/lib/liblzma-la3511.so.5 \
    && ln -fs /usr/lib64/libz.so ./src/extractcode_libarchive/lib/libz-la3511.so.1 \
    && ln -fs /usr/lib64/libzstd.so.1 ./src/extractcode_libarchive/lib/libzstd-la3511.so.1 \
    && python setup.py release \
    && pip install $(find ./dist/ -name "*.whl") \
    && cd /build/scancode-plugins/builtins/typecode_libmagic-linux \
    && sed -E \
        -e "s|manylinux1_x86_64|manylinux_2_34_${MANYLINUX_ARCHITECTURE}|" \
        -i ./setup.cfg \
    && ln -fs /usr/share/misc/magic.mgc ./src/typecode_libmagic/data/magic.mgc \
    && ln -fs /usr/lib64/libmagic.so ./src/typecode_libmagic/lib/libmagic.so \
    && ln -fs /usr/lib64/libz.so ./src/typecode_libmagic/lib/libz-lm539.so.1 \
    && python setup.py release \
    && pip install $(find ./dist/ -name "*.whl")

WORKDIR /build/scancode/

ARG SCANCODE_IO_VERSION

RUN SCANCODE_IO_PYPROJECT_TOML_FILE=$(wget -qO- "https://raw.githubusercontent.com/aboutcode-org/scancode.io/refs/tags/v${SCANCODE_IO_VERSION}/pyproject.toml") \
    && SOURCE_INSPECTOR_VERSION=$(echo "$SCANCODE_IO_PYPROJECT_TOML_FILE" | sed -nE "s|^.*source-inspector==([0-9.]+).*|\1|p") \
    && wget -q "https://raw.githubusercontent.com/aboutcode-org/source-inspector/refs/tags/v${SOURCE_INSPECTOR_VERSION}/requirements.txt" \
    && pip install "git+https://github.com/aboutcode-org/scancode.io.git@v${SCANCODE_IO_VERSION}" \
    && pip install -r requirements.txt

WORKDIR /project/

RUN dnf remove -y "$BUILD_DEPENDENCIES_DNF" \
    && dnf clean all \
    && pip uninstall -y $BUILD_DEPENDENCIES_PIP \
    && rm -rf /build/

ENTRYPOINT ["/usr/local/bin/scancode"]
