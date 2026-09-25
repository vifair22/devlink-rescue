#!/bin/bash
# Regenerate linux.defconfig from linux.fragment, against a kernel source tree
# of the version classic_defconfig pins:
#
#   board/classic/mkconfig.sh /path/to/linux-6.18.33
#
# allnoconfig is the base, so anything the fragment does not ask for is off.
# Fails if any requested option did not survive, which is what a dependency
# the fragment forgot, or an option renamed between kernels, looks like.
set -euo pipefail

src=$(readlink -f "$1")
here=$(dirname "$(readlink -f "$0")")
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

cd "$src"
ARCH=i386 scripts/kconfig/merge_config.sh -n -O "$out" "$here/linux.fragment" \
    > "$out/merge.log" 2>&1 || { cat "$out/merge.log"; exit 1; }
if grep -q "not in final .config" "$out/merge.log"; then
    grep -A2 "not in final .config" "$out/merge.log" >&2
    echo "mkconfig: options above did not take; fix linux.fragment" >&2
    exit 1
fi
make -s ARCH=i386 O="$out" savedefconfig
cp "$out/defconfig" "$here/linux.defconfig"
echo "wrote $here/linux.defconfig"
