#!/bin/sh

# Mounts sandbox/ as a tmpfs; minimizes SSD teardown for 2-test.sh.
# (This is completely optional.)

mkdir -p sandbox
sudo mount -o size=16M -t tmpfs none sandbox
