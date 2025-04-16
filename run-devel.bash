#!/bin/bash

set -e

# Set variables
IMAGE_NAME="ubuntu-noble-ros-jazzy"
IMAGE_TAG="latest"
CONTAINER_NAME="ros-jazzy"
ROS_DISTRO="jazzy"
ROS_VERSION=2
ROS_PYTHON_VERSION=3
ROS_DOMAIN_ID=42
ROS_LOCALHOST_ONLY=0
XAUTH=/tmp/.docker.xauth
XSOCK=/tmp/.X11-unix
USERNAME="host"
MOUNT_USER_DIR=/rootfs/database/


variables=($(cat .env | grep -v '#' | awk -F= '/=/ {print $1}'))

if [ ! -d "${MOUNT_USER_DIR}" ]; then
    mkdir -p "${MOUNT_USER_DIR}"

    if [ ! -d "${MOUNT_USER_DIR}" ]; then
        echo "Could not create ${MOUNT_USER_DIR}'s home"
        exit 1
    fi
fi

# Sets the name of the Docker container instance.
if [ ! -f "${MOUNT_USER_DIR}/.bashrc" ]; then
    if [ -e $(dirname "$(readlink -f "$0")")/rootfs/home/.bashrc ]; then
        cp "$(dirname "$(readlink -f "$0")")/rootfs/home/.bashrc" "${MOUNT_USER_DIR}/"
    fi
fi

# Build the Docker image
echo "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"

if [ ! "$(docker images | grep "${IMAGE_NAME}"  | awk '{ split($13,a,"/"); print $3 }')" ]; then
    docker build --force-rm --compress --no-cache=true -t "${IMAGE_NAME}:$IMAGE_TAG" \
        --build-arg BASE_IMAGE=$BASE_IMAGE \
        --build-arg USERNAME=$USERNAME \
        --build-arg ROS_DISTRO=$ROS_DISTRO \
        --build-arg ROS_VERSION=$ROS_VERSION \
        --build-arg ROS_PYTHON_VERSION=$ROS_PYTHON_VERSION \
        --build-arg ROS_DOMAIN_ID=$ROS_DOMAIN_ID \
        --build-arg ROS_LOCALHOST_ONLY=$ROS_LOCALHOST_ONLY \
        .
fi

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Check if a container with the same name is already running
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "Stopping existing container..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    
    # Run the container
    echo "Running container: $CONTAINER_NAME"

    # if [ ! -f $XAUTH ]; then
    #     touch $XAUTH
    #     xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
    # fi

    xhost +local:root
    

    if [ ! "$(docker ps -q -f name=${IMAGE_NAME})" ]; then
        if [ ! "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
            docker create -it \
                --privileged \
                --net host \
                --ipc="host" \
                --env="LC_ALL=en_US.utf8" \
                --env="TERM" \
                --env="DISPLAY=${DISPLAY}" \
                --env="SSH_AUTH_SOCK=$SSH_AUTH_SOCK" \
                --env="XAUTHORITY=${XAUTH}" \
                --env="ROS_DOMAIN_ID=${ROS_DOMAIN_ID}" \
                --env="ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY}" \
                --env="ROS_DISTRO=${ROS_DISTRO}" \
                --env="ROS_VERSION=${ROS_VERSION}" \
                --env="ROS_PYTHON_VERSION=${ROS_PYTHON_VERSION}" \
                --env="USER=${USERNAME}" \
                --device="/dev:/dev" \
                --volume="/dev:/dev" \
                --volume="/dev/dri:/dev/dri" \
                --volume="${XSOCK}:${XSOCK}:rw" \
                --volume="${XAUTH}:${XAUTH}:rw" \
                --privileged \
                --volume="${MOUNT_USER_DIR}:/home/${USERNAME}:rw" \
                --volume="${HOME}/.ssh:/home/${USERNAME}/.ssh" \
                --name="${CONTAINER_NAME}" \
                --workdir="/home/${USERNAME}" \
                "${IMAGE_NAME}:latest"
        fi
        docker start -ai ${CONTAINER_NAME}
    else
        docker exec -ti  -u root "${IMAGE_NAME}-container" /bin/bash
    fi
    
    # Check if container is running
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "Container started successfully!"
    else
        echo "Failed to start container."
    fi
else
    echo "Build failed!"
    exit 1
fi
