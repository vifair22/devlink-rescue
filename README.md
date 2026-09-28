# devlink-rescue

A small Linux image that carries a [devlink](https://git.airies.net/vifair22/devlink)
agent, for working on a stuck 32-bit-era PC over a serial cable, or over the
LAN when the machine's own `\DEVLINK\DEVLINK.KEY` is on its disk: hardware
survey, disk and filesystem repair, and getting Windows 9x, NT, 2000 and XP
installs booting again.

It produces a kernel and an initramfs. How they are booted is up to you; the
classic build also packs them into `devlink-recovery.iso`, a BIOS-only
isolinux CD with two entries, the second putting the kernel console on COM2
(`board/classic/isolinux.cfg`). The ISO carries the same two files byte for
byte, as `/isolinux/bzimage` and `/isolinux/initrd.xz`.

`docs/plan.md` has the design and the order of work.

## Building

Buildroot is pinned as a submodule (2026.02.3 LTS), with this repo as its
external tree.

```sh
git submodule update --init
make classic            # -> build/classic/images/{bzImage,rootfs.cpio.xz,devlink-recovery.iso}
make qemu-classic       # boot it as a Pentium with 32 MB, agent on a pty
make classic-menuconfig # change the config and save it back
```

The first build compiles an i586 musl toolchain and takes a while. The kernel
config is generated from `board/classic/linux.fragment` by
`board/classic/mkconfig.sh`; edit the fragment, not `linux.defconfig`.

To build the agent from a devlink working tree rather than the pinned commit,
put `DEVLINK_AGENT_OVERRIDE_SRCDIR = /path/to/devlink` in
`build/classic/local.mk`.

On a machine with Docker and no toolchain (binhost), fetch the sources where
there is a login for the private repos, copy the tree across, and build in
the container, which has Buildroot's prerequisites and nothing else:

```sh
make classic-source                  # here: every source into buildroot/dl
rsync -a --exclude build/ ./ HOST:DIR/
ssh HOST 'cd DIR && tools/build-in-docker.sh classic'
```
