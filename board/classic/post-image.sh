#!/bin/bash
# Compress the initramfs for the kernel that has to unpack it. Buildroot's own
# xz step uses -9, a 64 MiB dictionary, and the kernel's decoder allocates the
# whole dictionary: on a 32 MB machine it runs out of memory and the machine
# boots with no root. A 1 MiB dictionary costs little ratio at this size.
set -euo pipefail
images=$BINARIES_DIR

xz -9e --check=crc32 --lzma2=dict=1MiB -c "$images/rootfs.cpio" > "$images/rootfs.cpio.xz"
