#!/bin/bash
# Split the root in two, so the tools cost RAM compressed rather than unpacked.
#
# The root is merged-usr, so everything but /etc and friends is under /usr.
# All of /usr goes into an xz squashfs at /rescue/usr.sqfs, which inittab
# loop-mounts over /usr at boot. What stays in the initramfs's own /usr is only
# what boot needs before that mount, and what must keep working if it fails:
# busybox and its applets, musl, and the rescue notes. The agent lives outside
# /usr altogether, at /rescue/devlink-agent, so it is up whether or not the
# mount works (and can report why), and so an update can be put over it: the
# squashfs is read-only.
#
# Runs as a post-fakeroot script, on the copy of the target Buildroot makes for
# each filesystem image, so the real target stays whole for the next build.
set -euo pipefail
t=${1:?post-fakeroot.sh: no target directory given}
mksquashfs=$HOST_DIR/bin/mksquashfs

mkdir -p "$t/rescue"
mv "$t/usr/sbin/devlink-agent" "$t/rescue/devlink-agent"

# 128 KiB blocks: the kernel's decoder needs one block's worth of dictionary,
# and a larger block buys little ratio on binaries this size.
"$mksquashfs" "$t/usr" "$t/rescue/usr.sqfs" -comp xz -b 128K -noappend -no-progress -quiet

# What stays: busybox, every link that resolves to it, musl, and the notes.
early=$(mktemp -d)
keep() {
    local rel=$1
    mkdir -p "$early/$(dirname "$rel")"
    cp -a "$t/$rel" "$early/$rel"
}
for dir in usr/bin usr/sbin; do
    for f in "$t/$dir"/*; do
        [ -L "$f" ] || continue
        case $(readlink "$f") in
            busybox|*/busybox) keep "$dir/$(basename "$f")" ;;
        esac
    done
done
keep usr/bin/busybox
for f in "$t"/usr/lib/libc.so "$t"/usr/lib/ld-musl-*.so.1; do
    keep "usr/lib/$(basename "$f")"
done
keep usr/share/rescue

rm -rf -- "${t:?}/usr"
mv "$early/usr" "$t/usr"
rmdir "$early"
