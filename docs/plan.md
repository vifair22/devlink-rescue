# Plan

## What this is

A small Linux image that carries a devlink agent, so Claude can work on a
stuck 32-bit-era PC from the other end of a serial cable: survey its
hardware, repair its disks and filesystems, and bring a Windows 9x, NT, 2000
or XP install back to booting. The A21m work showed that a session driving a
machine through devlink works well once the agent is on the machine. This
image puts it on machines that cannot start their own OS.

How the image is booted (USB, CD, floppy chain, PXE) is out of scope. This
repo produces a kernel and an initramfs; getting them onto a machine is a
separate problem.

Anything 64-bit is out of scope too: it runs the regular Arch rescue stick.

## Two images

- **classic**: the floor. i586, serial only, as little RAM as it can manage.
  For 9x and NT-era machines, which are the ones that are picky. Built first.
- **modern**: XP-era machines, serial and networking. Deferred until classic
  works; it is expected to be the classic image plus NIC drivers, a network
  stack and a decision about how the agent authenticates on a LAN.

Nothing older than 9x/NT is a goal. DOS-era machines are easy enough to work
on by hand.

## Classic image

### Target

- **CPU: i586** (`CONFIG_M586TSC`). A 2025 kernel proposal would drop CPUs
  without a TSC or CMPXCHG8B; the Pentium has both, so a current kernel
  serves this floor whether or not that lands. A few non-Intel 586-class
  parts lack a TSC; they are handled if one turns up.
- **RAM: 32 MB**, 16 MB as a stretch. Measured, not guessed at: it boots and
  serves the agent at 32 MB with 13 MB free (2026-09-25). 24 MB fails before
  unpacking: the kernel reports an invalid archive at the top of memory, where
  QEMU loads it, which looks like early boot overwriting it rather than a
  shortage. Open.
- **Link: serial only.** The agent owns COM1 (`ttyS0`) at 115200. The kernel
  console goes to the VGA text console, never the agent's port, since boot
  messages on that line would land in the middle of frames. A build option
  puts the console on COM2 (`ttyS1`) for bringing the image up.

### Shape

- The whole userland is an initramfs and runs from RAM. Nothing touches a
  disk unless the session asks, which matters when the disk is the fault.
- **The tools are a squashfs inside it.** Unpacked, the root was 12.6 MB and
  did not fit 32 MB beside the archive it came from. With merged /usr, all of
  /usr is packed into an xz squashfs (`/rescue/usr.sqfs`, 128 KiB blocks) and
  loop-mounted over /usr at boot, so the tools cost RAM compressed plus cache
  for what is in use. The initramfs keeps a real /usr of busybox, musl and the
  notes, which is what boot needs and what still works if the mount fails.
  The agent sits outside /usr at `/rescue/devlink-agent`, so it starts either
  way and can be updated with a put. The initramfs unpacks to 6.4 MB.
- busybox `init` runs the agent on `ttyS0` and respawns it, so a crashed agent
  comes back rather than leaving the machine unreachable.
- The agent is statically linked against musl, `-march=i586`, from the devlink
  source. One binary, no loader, no library versions to match.
- The kernel carries what these machines have: IDE/PATA, a few SCSI HBAs,
  FAT/VFAT, FUSE (for NTFS), the 8250 UART, PCI, and USB mass storage on
  UHCI/OHCI. No sound, no graphics beyond VGA text, no networking.

### Toolkit

| Job | Tools |
|---|---|
| NT recovery | ntfs-3g; chntpw and reged for offline SAM and registry work; ms-sys for MBR and NT/2000/XP boot sectors; plain editing for `BOOT.INI` |
| 9x recovery | dosfstools; ms-sys for FAT32 9x boot records; `IO.SYS` and friends copied by hand in place of `SYS C:` |
| Hardware survey | lspci, dmidecode, `/proc/cpuinfo`, hdparm `-I`, smartctl, lsusb, memtester |
| FAT12/16/32 | dosfstools (`mkfs.fat`, `fsck.fat`, `fatlabel`), mtools |
| NTFS | ntfs-3g and ntfsprogs (`mkntfs`, `ntfsfix`, `ntfsresize`, `ntfsclone`, `ntfslabel`, `ntfsundelete`, `ntfsinfo`) |
| ext2/3/4 | e2fsprogs (`mke2fs`, `e2fsck`, `resize2fs`, `tune2fs`) |
| Partitions | util-linux `fdisk`, `sfdisk`, `wipefs`, `blkid`, `lsblk`; parted and fatresize if FAT32 resizing earns libparted |
| Imaging | ddrescue, dd |

Decided against:

- **TestDisk / PhotoRec.** Partition-table recovery and file carving. Left
  out by choice (2026-09-25).
- **The kernel's ntfs3** in place of ntfs-3g. Smaller, but less trusted on a
  damaged volume, and a rescue image meets damaged volumes.

Found while packaging (2026-09-25):

- **chntpw is built without DOCRYPTO.** That drops OpenSSL entirely, at the
  cost of setting new passwords; it can still blank them, which its own source
  calls the reliable operation on XP and later anyway.
- **ms-sys has no NT5 NTFS boot record**, only Windows 7's, which loads
  BOOTMGR rather than NTLDR. A 2000/XP NTFS boot sector is restored from the
  backup copy NTFS keeps in the volume's last sector (dd, or `ntfsfix`). Its
  MBRs (95B/98/ME, 2000/XP) and FAT boot records are all there.
- **usbutils is out**: Buildroot's needs udev. busybox's `lsusb` reads sysfs,
  which is enough for a survey. hwclock is busybox's too.
- **hdparm is the full one**, not busybox's, for `-I`.

Open:

- **cabextract.** 9x keeps registry backups as `RB00x.CAB`; Buildroot has
  libmspack but no cabextract binary. A small package here would make that
  restore possible without another machine.

- **`pci.ids`** is over 1 MB. Trim it to vendors and devices before about 2005,
  or compress it; decided when the image size is known.
- **The 9x registry.** `SYSTEM.DAT` and `USER.DAT` are the 9x `CREG` format,
  which chntpw does not read. No small maintained Linux tool is known. Most 9x
  registry recovery is restoring `SYSTEM.1ST` or an `RB00x.CAB` backup, which
  is file copying, so this does not block anything. A small C library later,
  maybe.

### Things the tools will not tell a session

These go in the image's own notes for whoever drives it, because each one
fails quietly:

- **Partition alignment.** Modern `fdisk` starts partitions at 1 MiB. DOS, 9x
  and some BIOSes of the period expect cylinder alignment (the first partition
  at sector 63, ends on cylinder boundaries). Partitions for these machines
  are made in DOS-compatible, cylinder-aligned mode.
- **Geometry in the boot sector.** NTLDR's and IO.SYS's boot code read the disk
  by the heads and sectors-per-track recorded in the filesystem's boot sector.
  `mkntfs` and `mkfs.fat` must be given the geometry the BIOS uses (`-H`,
  `-S` and friends), or the volume formats cleanly and never boots.

## Build

Buildroot, as an external tree (`BR2_EXTERNAL`) in this repo:
`classic_defconfig` now, `modern_defconfig` later. A musl toolchain for i586,
the devlink agent as a local package built from the devlink source, and the
tools above, most of which Buildroot already packages (ms-sys and chntpw may
need package files here). One `make` yields a kernel and an initramfs.

## Order of work

1. **This plan.**
2. **The Linux agent, in devlink.** `src/core/agent.c` is already
   platform-neutral and `src/posix/` already has serial, process, filesystem
   and clock layers; the agent loop is tested on Linux over a pty. What is
   missing is a Linux `main.c`, a static i586 musl build target, and an audit
   of the client for places it assumes the target is Windows (drive letters,
   `cmd.exe` quoting, `C:\`-shaped defaults). Where the client must differ it
   asks the peer what it is at the handshake, rather than forking the code.
   Testable here over a pty before any image exists.
3. **The classic image**, booted in QEMU as `-cpu pentium -m 32M` with its
   serial port on a pty, driven by the devlink client. The whole image is
   tested without real hardware.
4. **Real hardware**, when there is a machine to try it on.
5. **The modern image.**
