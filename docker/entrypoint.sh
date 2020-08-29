#!/bin/bash

HOST_UID=${HOST_UID:-$(stat -c %u $PWD)}
HOST_GID=${HOST_GID:-$(stat -c %g $PWD)}

[[ $HOST_UID -ne $(id -u user) ]] \
  && usermod -u $HOST_UID -o -m user -d /home/user
[[ $HOST_GID -ne $(id -g user) ]] \
  && groupmod -g $HOST_GID user

exec /usr/sbin/gosu user "$@"
