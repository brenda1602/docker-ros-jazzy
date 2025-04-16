#!/bin/bash
set -e

debug() {
  if [ ! -z "${DEBUG}" ]; then
    if [ "${DEBUG}" -eq 1 ]; then
      printf -- " -- \e[1;32m$1\e[0m\n"
    fi
  fi
}

debug "Container run $0 ..."

# print_green() {
#     echo -e "\e[1;32m=== $1 ===\e[0m"
# }

# # cat <<EOL >> ~/.bashrc

# PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;36m\]\$(parse_git_branch)\[\033[00m\]\$ '

# echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

exec "$@"
