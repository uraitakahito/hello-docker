#!/bin/bash

set -eo pipefail

if [ $# != 3 ]; then
    echo "Argument values are: " $*
    exit 1
fi

SHELL_NAME=$0
GROUP_ID=$1
USER_ID=$2
USER_NAME=$3

echo "[$SHELL_NAME] START"

# Add g group
if getent group "$GROUP_ID" > /dev/null 2>&1; then
    echo "[$SHELL_NAME] GROUP_ID '$GROUP_ID' already exists."
else
    echo "[$SHELL_NAME] GROUP_ID '$GROUP_ID' does NOT exist. So add it."
    groupadd -g $GROUP_ID $GROUP_NAME
fi

# Add a superuser
if getent passwd "$USER_ID" > /dev/null 2>&1; then
    echo "[$SHELL_NAME] USER_ID '$USER_ID' already exists."
else
    echo "[$SHELL_NAME] USER_ID '$USER_ID' does NOT exist. So add it."
    useradd -m -s /bin/zsh -u $USER_ID -g $GROUP_ID $USER_NAME
    echo "$USER_NAME:$USER_NAME" | chpasswd
    adduser $USER_NAME sudo
    echo "%${USER_NAME}    ALL=(ALL)   NOPASSWD:    ALL" >> /etc/sudoers.d/${USER_NAME}
    chmod 0440 /etc/sudoers.d/${USER_NAME}
fi

echo "[$SHELL_NAME] FINISH"
