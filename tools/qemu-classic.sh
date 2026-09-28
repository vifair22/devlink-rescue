#!/bin/bash
# Boot the classic image in QEMU as the floor machine: a Pentium with 32 MB.
#
#   tools/qemu-classic.sh               boot it; Ctrl-C to stop
#   MEM=16M tools/qemu-classic.sh       try another amount of RAM
#   DISK=win98.img tools/qemu-classic.sh   with a disk image as the first IDE disk
#   QEMU=qemu-system-x86_64 tools/qemu-classic.sh   where there is no i386
#                                       build; -cpu pentium makes it the same
#
# COM1 is a pty linked at build/qemu/com1, which is where the agent listens:
#   DEVLINK_LINE=build/qemu/com1 devlink info
# COM2 carries the kernel console (console=ttyS1), logged to
# build/qemu/console.log, since a headless run has no VGA screen to watch.
set -euo pipefail

root=$(dirname "$(readlink -f "$0")")/..
images=$root/build/classic/images
run=$root/build/qemu
mem=${MEM:-32M}
mkdir -p "$run"
rm -f "$run/com1"

disk=()
if [ -n "${DISK:-}" ]; then
    disk=(-drive "file=$DISK,format=raw,if=ide,index=0")
fi

echo "COM1 (agent): $run/com1    console: $run/console.log"
exec "${QEMU:-qemu-system-i386}" \
    -cpu pentium -m "$mem" -no-reboot \
    -display none -monitor none \
    -kernel "$images/bzImage" -initrd "$images/rootfs.cpio.xz" \
    -append "console=ttyS1,115200" \
    -chardev "pty,id=com1,path=$run/com1" -serial chardev:com1 \
    -serial "file:$run/console.log" \
    "${disk[@]}"
