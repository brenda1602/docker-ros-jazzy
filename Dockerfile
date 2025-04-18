FROM osrf/ros:jazzy-desktop-full

ARG USERNAME=${USERNAME:-admin}

ENV LANG=en_US.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE="1" \
    GALLIUM_DRIVER="softpipe"

RUN apt update && apt install -y python3-venv

RUN python3 -m venv /opt/venv

RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    apt-transport-https \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    git \
    pkg-config \
    sudo \
    wget \
    gnupg2 \
    tzdata \
    locales \
    ssh-client \
    python3-pip \
    wget \
    xvfb \
    doxygen \
    dbus-x11 \
    ros-jazzy-rqt \
    ros-jazzy-rqt-common-plugins && \
    pip3 install --break-system-packages dcf-tools && \
    rm -rf /var/lib/apt/lists/*

# Create catkin workspace
WORKDIR /home/$USERNAME/
RUN /bin/bash -c "source /opt/ros/jazzy/setup.bash"

RUN useradd -m $USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    usermod --shell /bin/bash $USERNAME && \
    usermod -aG sudo $USERNAME && \
    usermod -aG video $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    # usermod  --uid 1000 $USERNAME && \
    # groupmod --gid 1000 $USERNAME && \
    ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo Etc/UTC > /etc/timezone

# setup entrypoint
COPY rootfs/home/.bashrc /home/$USERNAME
COPY rootfs/entrypoint.bash /entrypoint.bash
RUN chmod +x /entrypoint.bash

ENTRYPOINT ["bash", "/entrypoint.bash"]

CMD ["bash"]
