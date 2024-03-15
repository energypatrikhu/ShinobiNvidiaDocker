#
# Builds a custom docker image for ShinobiCCTV Pro with NVIDIA support
#
FROM ubuntu:20.04

LABEL Author="MiGoller, mrproper, pschmitt & moeiscool (Edited by EnergyPatrikHU)"

# Add additional repositories
RUN apt update && \
    apt install -y software-properties-common && \
    add-apt-repository main && \
    add-apt-repository universe && \
    add-apt-repository restricted && \
    add-apt-repository multiverse && \
    apt update

# Set environment variables to default values
# ADMIN_USER : the super user login name
# ADMIN_PASSWORD : the super user login password
# PLUGINKEY_MOTION : motion plugin connection key
# PLUGINKEY_OPENCV : opencv plugin connection key
# PLUGINKEY_OPENALPR : openalpr plugin connection key
ENV ADMIN_USER=admin@shinobi.video \
    ADMIN_PASSWORD=admin \
    CRON_KEY=fd6c7849-904d-47ea-922b-5143358ba0de \
    PLUGINKEY_MOTION=b7502fd9-506c-4dda-9b56-8e699a6bc41c \
    PLUGINKEY_OPENCV=f078bcfe-c39a-4eb5-bd52-9382ca828e8a \
    PLUGINKEY_OPENALPR=dbff574e-9d4a-44c1-b578-3dc0f1944a3c \
    #leave these ENVs alone unless you know what you are doing
    MYSQL_USER=majesticflame \
    MYSQL_PASSWORD=password \
    MYSQL_HOST=localhost \
    MYSQL_DATABASE=ccio \
    MYSQL_ROOT_PASSWORD=blubsblawoot \
    MYSQL_ROOT_USER=root \
    DEBIAN_FRONTEND=noninteractive

# Create the custom configuration dir
RUN mkdir -p /config

# Create the working dir
RUN mkdir -p /opt/shinobi

# Install base package dependencies
RUN apt install -y \
    sudo \
    wget \
    git


#
# Install nvidia drivers, cuda & cudnn
#

# Add nvidia cuda repo
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin && \
    mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub && \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"

# Add nvidia cudnn keyring
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.1-1_all.deb && \
    sudo dpkg -i cuda-keyring_1.1-1_all.deb

# Install nvidia driver
RUN apt install -y *nvidia*470

# Install cuda
RUN apt install -y cuda-drivers=470* *cuda*470* *cuda*11-4*

# Install cudnn
RUN apt install -y *cudnn*cuda*11*

# Add cuda & cudnn to ENV
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64" \
    CUDA_HOME=/usr/local/cuda \
    PATH="/usr/local/cuda/bin:$PATH"

RUN echo 'LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"' >> /etc/environment && \
    echo 'CUDA_HOME=/usr/local/cuda' >> /etc/environment && \
    echo 'PATH="/usr/local/cuda/bin:$PATH"' >> /etc/environment

# Install database
RUN apt install -y \
    mariadb-server \
    mariadb-client
RUN sed -ie "s/^bind-address\s*=\s*127\.0\.0\.1$/#bind-address = 0.0.0.0/" /etc/mysql/my.cnf


#
# Build ffmpeg with NVENC support & extras
#

# Install dependencies
RUN apt install -y \
    autoconf \
    automake \
    build-essential \
    cmake \
    curl \
    dssi-dev \
    flite1-dev \
    frei0r-plugins-dev \
    gnutls-bin \
    libaom-dev \
    libaribb24-dev \
    libass-dev \
    libavc1394-dev \
    libbluray-dev \
    libbs2b-dev \
    libcaca-dev \
    libchromaprint-dev \
    libcodec2-dev \
    libdc1394-dev \
    libdrm-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libfribidi-dev \
    libgcrypt20-dev \
    libgme-dev \
    libgnutls28-dev \
    libgsm1-dev \
    libharfbuzz-dev \
    libiec61883-dev \
    libjack-dev \
    liblilv-dev \
    liblzma-dev \
    libmbedtls-dev \
    libmodplug-dev \
    libmp3lame-dev \
    libmysofa-dev \
    libopenal-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libopengl-dev \
    libopenjp2-7-dev \
    libopenmpt-dev \
    libplacebo-dev \
    libpulse-dev \
    librtmp-dev \
    librubberband-dev \
    libshine-dev \
    libsmbclient-dev \
    libsnappy-dev \
    libsoxr-dev \
    libspeex-dev \
    libsrtp2-dev \
    libtool \
    libunistring-dev \
    libvo-amrwbenc-dev \
    libvorbis-dev \
    libwebp-dev \
    libxcb-shape0-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    libxcb1-dev \
    libxml2-dev \
    libxvidcore-dev \
    libzmq3-dev \
    libzvbi-dev \
    lv2-dev \
    m4 \
    nasm \
    ninja-build \
    nvidia-opencl-dev \
    pkg-config \
    python3-pip \
    texinfo \
    unzip \
    yasm

RUN python3 -m pip install meson

RUN mkdir -p /opt/ffmpeg/{sources,build}

WORKDIR /opt/ffmpeg/sources

# Build libx264
RUN git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
    cd x264 && \
    PATH="/usr/bin:$PATH" PKG_CONFIG_PATH="/opt/ffmpeg/build/lib/pkgconfig" ./configure --prefix="/opt/ffmpeg/build" --bindir="/usr/bin" --enable-static --enable-pic && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install

# Build libx265
RUN wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 && \
    tar xjvf x265.tar.bz2 && \
    cd multicoreware*/build/linux && \
    PATH="/usr/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/opt/ffmpeg/build" -DENABLE_SHARED=off ../../source && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install

# Build nvenc
RUN git clone -b n11.1.5.3 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    make -j$(nproc) && \
    make -j$(nproc) install PREFIX="/opt/ffmpeg/build"

# Build libfdk-aac
RUN git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --prefix="/opt/ffmpeg/build" --disable-shared && \
    make -j$(nproc) && \
    make -j$(nproc) install

# Build libvpx
RUN git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    PATH="/usr/bin:$PATH" ./configure --prefix="/opt/ffmpeg/build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install

# Build libopus
RUN git -C opus pull 2> /dev/null || git clone --depth 1 https://github.com/xiph/opus.git && \
    cd opus && \
    ./autogen.sh && \
    ./configure --prefix="/opt/ffmpeg/build" --disable-shared && \
    make -j$(nproc) && \
    make -j$(nproc) install

# Build libdav1d
RUN git -C dav1d pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/dav1d.git && \
    mkdir -p dav1d/build && \
    cd dav1d/build && \
    meson setup -Denable_tools=false -Denable_tests=false --default-library=static .. --prefix "/opt/ffmpeg/build" --libdir="/opt/ffmpeg/build/lib" && \
    ninja && \
    ninja install

# Build libsvtav1
RUN git -C SVT-AV1 pull 2> /dev/null || git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
    mkdir -p SVT-AV1/build && \
    cd SVT-AV1/build && \
    PATH="/usr/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/opt/ffmpeg/build" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF .. && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install

# Build libaribcaption
RUN git clone https://github.com/xqq/libaribcaption.git && \
    cd libaribcaption && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . && \
    sudo cmake --install . --prefix /opt/ffmpeg/build

# Build libilbc
RUN git clone --depth=1 https://github.com/TimothyGu/libilbc.git && \
    cd libilbc && \
    git submodule update --init && \
    cmake -DBUILD_SHARED_LIBS=OFF . && \
    cmake --build . && \
    sudo cmake --install . --prefix /opt/ffmpeg/build

# Build libklvanc
RUN git clone https://github.com/stoth68000/libklvanc.git && \
    cd libklvanc && \
    ./autogen.sh --build && \
    ./configure --enable-shared=no && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install

# Build libvmaf
RUN wget -O vmaf.tar.gz https://api.github.com/repos/Netflix/vmaf/tarball && \
    tar xvf vmaf.tar.gz && \
    mkdir -p $(ls | grep -wv 'tar.gz' | grep vmaf)/libvmaf/build && \
    cd $(ls | grep -wv 'tar.gz' | grep vmaf)/libvmaf/build && \
    meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static .. --prefix "/opt/ffmpeg/build" --bindir="/opt/ffmpeg/build/bin" --libdir="/opt/ffmpeg/build/lib" && \
    ninja && \
    sudo ninja install

# Build libkvazaar
RUN git clone https://github.com/ultravideo/kvazaar.git && \
    cd kvazaar && \
    ./autogen.sh && \
    ./configure && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install && \
    sudo ldconfig

# Build ffmpeg
RUN wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
    tar xjvf ffmpeg-snapshot.tar.bz2 && \
    cd ffmpeg && \
    PATH="/usr/bin:$PATH" PKG_CONFIG_PATH="/opt/ffmpeg/build/lib/pkgconfig" ./configure \
    --prefix="/opt/ffmpeg/build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I/opt/ffmpeg/build/include" \
    --extra-ldflags="-L/opt/ffmpeg/build/lib" \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --bindir="/usr/bin" \
    --cpu=native \
    --extra-libs="-lpthread -lm -lz" \
    --enable-chromaprint \
    --enable-cuda-nvcc \
    --enable-frei0r \
    --enable-gcrypt \
    --enable-gmp \
    --enable-gnutls \
    --enable-gpl \
    --enable-gray \
    --enable-ladspa \
    --enable-libaom \
    --enable-libaribb24 \
    --enable-libaribcaption \
    --enable-libass \
    --enable-libbluray \
    --enable-libbs2b \
    --enable-libcaca \
    --enable-libcodec2 \
    --enable-libdav1d \
    --enable-libdc1394 \
    --enable-libdrm \
    --enable-libfdk-aac \
    --enable-libflite \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libgme \
    --enable-libgsm \
    --enable-libharfbuzz \
    --enable-libiec61883 \
    --enable-libilbc \
    --enable-libjack \
    --enable-libklvanc \
    --enable-libkvazaar \
    --enable-libmodplug \
    --enable-libmp3lame \
    --enable-libmysofa \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopenmpt \
    --enable-libopus \
    --enable-libpulse \
    --enable-librtmp \
    --enable-librubberband \
    --enable-libshine \
    --enable-libsmbclient \
    --enable-libsnappy \
    --enable-libsoxr \
    --enable-libspeex \
    --enable-libsvtav1 \
    --enable-libvmaf \
    --enable-libvo-amrwbenc \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxcb \
    --enable-libxcb-shape \
    --enable-libxcb-shm \
    --enable-libxcb-xfixes \
    --enable-libxml2 \
    --enable-libxvid \
    --enable-libzmq \
    --enable-libzvbi \
    --enable-lv2 \
    --enable-nonfree \
    --enable-openal \
    --enable-opencl \
    --enable-opengl \
    --enable-version3 && \
    PATH="/usr/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install && \
    hash -r


#
# Clone & install Shinobi & dependencies
#

# Install latest NodeJS
RUN apt install gnupg2 -y
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
RUN apt install nodejs -y

WORKDIR /opt/shinobi

# Clone the Shinobi CCTV PRO repo
RUN git clone https://github.com/energypatrikhu/Shinobi.git /opt/shinobi

# Install NodeJS dependencies
RUN npm install npm@latest -g
RUN npm install pm2@latest -g
RUN npm install

# Copy code
COPY pm2Shinobi.yml .
COPY docker-entrypoint.sh .
RUN chmod -f +x ./*.sh

# Copy default configuration files
COPY ./config/conf.sample.json /opt/shinobi/conf.sample.json
COPY ./config/super.sample.json /opt/shinobi/super.sample.json
COPY ./config/motion.sample.json /opt/shinobi/motion.sample.json

VOLUME ["/config"]
VOLUME ["/opt/shinobi/libs/customAutoLoad"]
VOLUME ["/var/lib/mysql"]
VOLUME ["/opt/shinobi/videos"]
VOLUME ["/opt/shinobi/plugins"]

EXPOSE 8080

ENTRYPOINT ["/opt/shinobi/docker-entrypoint.sh"]

CMD ["pm2-docker", "pm2Shinobi.yml"]
