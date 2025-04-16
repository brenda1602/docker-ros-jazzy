#!/bin/bash
set -e

echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

exec "$@"
