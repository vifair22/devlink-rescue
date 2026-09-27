#!/bin/bash
# Compress the initramfs for the kernel that has to unpack it. Buildroot's own
# xz step uses -9, a 64 MiB dictionary, and the kernel's decoder allocates the
# whole dictionary: on a 32 MB machine it runs out of memory and the machine
# boots with no root. A 1 MiB dictionary costs little ratio at this size.
set -euo pipefail
images=$BINARIES_DIR

xz -9e --check=crc32 --lzma2=dict=1MiB -c "$images/rootfs.cpio" > "$images/rootfs.cpio.xz"

# The ISO carries those two files byte for byte, under 8.3 names so a loader
# that reads plain ISO9660 without Rock Ridge finds the same paths isolinux
# does. isolinux.cfg keeps each entry to LABEL/KERNEL/INITRD/APPEND, which is what
# such a loader parses to boot the kernel itself; the MENU and UI lines are
# for isolinux's own menu and can be ignored.
board=$(dirname "$(readlink -f "$0")")
iso=$(mktemp -d)
trap 'rm -rf "$iso"' EXIT
install -D -m 0644 "$images/syslinux/isolinux.bin" "$iso/isolinux/isolinux.bin"
install -D -m 0644 "$HOST_DIR/share/syslinux/ldlinux.c32" "$iso/isolinux/ldlinux.c32"
install -D -m 0644 "$board/isolinux.cfg" "$iso/isolinux/isolinux.cfg"
for c32 in menu.c32 libutil.c32 libcom32.c32; do
    install -D -m 0644 "$images/syslinux/$c32" "$iso/isolinux/$c32"
done
install -D -m 0644 "$images/bzImage" "$iso/isolinux/bzimage"
install -D -m 0644 "$images/rootfs.cpio.xz" "$iso/isolinux/initrd.xz"
"$HOST_DIR/bin/xorriso" -as mkisofs -quiet -R -J -V DEVLINK_RESCUE \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o "$images/devlink-recovery.iso" "$iso"
