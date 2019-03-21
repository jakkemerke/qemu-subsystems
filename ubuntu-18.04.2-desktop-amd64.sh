#!/usr/bin/env bash

# Copied from https://github.com/cirosantilli/linux-cheat/commit/d3f524e59b2d3042de2daee46a0ae241e2a16766
# Tested on: Ubuntu 18.10.
# https://askubuntu.com/questions/884534/how-to-run-ubuntu-16-04-desktop-on-qemu/1046792#1046792

set -eux

id=ubuntu-18.04.2-desktop-amd64
OPTIND=1
while getopts i: OPT; do
  case "$OPT" in
    i)
      id="$OPTARG"
      ;;
  esac
done
shift "$(($OPTIND - 1))"

disk_img="${id}.img.qcow2"
disk_img_snapshot="${id}.snapshot.qcow2"
iso="${id}.iso"

# Get image.
if [ ! -f "$iso" ]; then
  wget "http://releases.ubuntu.com/18.04/${iso}"
fi

# Go through installer manually.
if [ ! -f "$disk_img" ]; then
  qemu-img create -f qcow2 "$disk_img" -o size=9G
  qemu-system-x86_64 \
    -cdrom "$iso" \
    -drive "file=${disk_img},format=qcow2" \
    -enable-kvm \
    -m 2G \
    -smp 2 \
  ;
fi

# Snapshot the installation.
if [ ! -f "$disk_img_snapshot" ]; then
  qemu-img \
    create \
    -b "$disk_img" \
    -f qcow2 \
    "$disk_img_snapshot" \
  ;
fi

# Run the installed image.
qemu-system-x86_64 \
  -drive "file=${disk_img_snapshot},format=qcow2" \
  -enable-kvm \
  -m 2G \
  -serial mon:stdio \
  -smp 2 \
  -soundhw hda \
  -vga virtio \
  "$@" \
;
