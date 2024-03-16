#
# Builds a custom docker image for ShinobiCCTV Pro with NVIDIA support
#
# FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04
FROM nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04

LABEL Author="MiGoller, mrproper, pschmitt & moeiscool (Edited by EnergyPatrikHU)"

# Set environment variables to default values
# ADMIN_USER : the super user login name
# ADMIN_PASSWORD : the super user login password
# PLUGINKEY_MOTION : motion plugin connection key
# PLUGINKEY_OPENCV : opencv plugin connection key
# PLUGINKEY_OPENALPR : openalpr plugin connection key
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_REQUIRE_CUDA="cuda=11.4 driver=470" \
    ADMIN_USER=admin@shinobi.video \
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

# Install package dependencies
RUN apt update && \
    apt install -y \
    sudo \
    curl \
    wget \
    git \
    gnupg2 \
    mariadb-server \
    mariadb-client \
    ffmpeg \
    libffmpeg*

# Bind database to 0.0.0.0
RUN sed -ie "s/^bind-address\s*=\s*127\.0\.0\.1$/#bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# Add NodeJS repository
RUN curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash -
RUN apt update
RUN apt install -y nodejs

#
# Clone & install custom Shinobi & dependencies
#
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
COPY ./config/motion.conf.sample.json /opt/shinobi/motion.sample.json

VOLUME ["/config"]
VOLUME ["/var/lib/mysql"]
VOLUME ["/opt/shinobi/libs/customAutoLoad"]
VOLUME ["/opt/shinobi/videos"]
VOLUME ["/opt/shinobi/plugins"]

EXPOSE 8080

ENTRYPOINT ["/opt/shinobi/docker-entrypoint.sh"]

CMD ["pm2-docker", "pm2Shinobi.yml"]
