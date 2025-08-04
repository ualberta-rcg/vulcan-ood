#!/bin/bash
# Needed on Compute Hosts Where OOD Jobs are Run

mkdir -p /tmp/.ICE-unix
chown -R root:root /tmp/.ICE-unix
chmod 1777 /tmp/.ICE-unix

rm -rf "/run/user/$1"
ln -sfn "/tmp/xdg-runtime-$1" "/run/user/$1"

