#!/bin/bash
# Remove what packages install and a rescue session will never run. The whole
# root lives in RAM on a machine that may have 32 MB, so every file here costs
# memory, not just space. Listed by name, so each removal is a decision.
set -euo pipefail
target=${1:?post-build.sh: no target directory given}

unwanted=(
    # smartctl stays; smartd is a monitoring daemon.
    usr/sbin/smartd usr/sbin/update-smart-drivedb etc/smartd.conf etc/init.d/S*smartd*
    # util-linux's BINARIES brings these along with fdisk, sfdisk and lsblk.
    usr/bin/lsns usr/bin/lsipc usr/bin/script usr/bin/scriptlive
    usr/bin/scriptreplay usr/bin/choom usr/bin/lsclocks usr/bin/setarch
    usr/bin/lslocks usr/sbin/rtcwake sbin/blkzone sbin/fstrim bin/pipesz
    usr/bin/uclampset usr/bin/lsirq usr/bin/irqtop sbin/swapon sbin/swapoff
    sbin/mkswap sbin/swaplabel sbin/zramctl sbin/chcpu
    # Headers and data for building things, never read at run time.
    usr/share/et usr/share/ss
)
for f in "${unwanted[@]}"; do
    # Globs are expanded against the target tree; a name that is not there
    # is not an error, since package contents shift between versions.
    for g in "$target"/$f; do
        [ -e "$g" ] || [ -L "$g" ] || continue
        rm -rf -- "$g"
    done
done
