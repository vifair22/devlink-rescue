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

## One image

Decided 2026-09-27: one image, with networking. The plan had two, a serial-only
**classic** for the picky 9x and NT machines and a **modern** one adding a
network for XP-era machines, deferred until classic worked. Measured, the
network stack and the era's Ethernet drivers cost about 3.3 MB of RAM at the
32 MB floor, which leaves 10 MB, so the split bought nothing worth a second
image. The build and its files keep the name classic.

The image is for 32-bit machines that cannot boot the regular Arch rescue
stick; anything 64-bit runs that instead. Its drivers are the common hardware
of that era and no more.

Nothing older than 9x/NT is a goal. DOS-era machines are easy enough to work
on by hand.

## Classic image

### Target

- **CPU: i586** (`CONFIG_M586TSC`). A 2025 kernel proposal would drop CPUs
  without a TSC or CMPXCHG8B; the Pentium has both, so a current kernel
  serves this floor whether or not that lands. A few non-Intel 586-class
  parts lack a TSC; they are handled if one turns up.
- **RAM: 32 MB**, 16 MB as a stretch. Measured, not guessed at: it boots and
  serves the agent at 32 MB with 13 MB free (2026-09-25), and 10 MB available
  with the network up and a TCP session open (2026-09-27). With the full disk
  toolkit (a 5.8 MB tools squashfs), 8.1 MB available with the network up
  (2026-09-27, later). 24 MB fails before
  unpacking: the kernel reports an invalid archive at the top of memory, where
  QEMU loads it, which looks like early boot overwriting it rather than a
  shortage. Open.
- **Link: serial, and TCP when there is a key.** The agent owns COM1
  (`ttyS0`) at 115200. The kernel console goes to the VGA text console, never
  the agent's port, since boot messages on that line would land in the middle
  of frames. A build option puts the console on COM2 (`ttyS1`) for bringing
  the image up.
- TCP is devlink's own (Noise, pre-shared passphrase) on port 2098, served
  beside serial. Every Ethernet interface gets DHCP at boot (`/rescue/net-up`,
  busybox udhcpc, in the background so a LAN without DHCP holds nothing up).
  The passphrase is the machine's own: `/rescue/find-key` looks for
  `\DEVLINK\DEVLINK.KEY`, which the machine's Windows agent keeps, on each
  NTFS and FAT partition before the agent starts, read-only and with every
  mount under a timeout. That is the one disk read the image makes unasked. No
  key found means no TCP until one is put over serial
  (`devlink put KEY /rescue/DEVLINK.KEY`, then `@stop`). No key is ever built
  into the image: anyone with the ISO would hold it.

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
  FAT/VFAT, FUSE (for NTFS), the 8250 UART, PCI, PC Card and CardBus sockets
  (a CF card in one is a disk), USB mass storage on UHCI/OHCI, and Ethernet:
  PCI and CardBus (e100, e1000, 8139, r8169, tulip and relatives, pcnet32,
  3c59x, ne2k-pci, via-rhine, sis900, natsemi, forcedeth, b44, tg3, skge,
  sky2), 16-bit PC Card (NE2000-class, 3c589/574, SMC91C92, Xircom,
  Fujitsu) and USB (ASIX, CDC, Pegasus, RTL8150). IPv4 only. No sound, no
  graphics beyond VGA text, no wireless.
- Ctrl-Alt-Del reboots and the ACPI power button powers off (busybox acpid).
  Both depend on the kernel's 32-bit time system calls, which allnoconfig
  drops: musl uses them, and without them busybox init spun at 100% CPU and
  acted on no signal at all. Found on the A21m, 2026-09-27; see
  board/classic/linux.fragment.

### Toolkit

| Job | Tools |
|---|---|
| NT recovery | ntfs-3g; chntpw and reged for offline SAM and registry work; ms-sys for MBR and NT/2000/XP boot sectors; plain editing for `BOOT.INI` |
| 9x recovery | dosfstools; ms-sys for FAT32 9x boot records; `IO.SYS` and friends copied by hand in place of `SYS C:` |
| Hardware survey | lspci, dmidecode, `/proc/cpuinfo`, hdparm `-I`, smartctl, lsusb, memtester |
| FAT12/16/32 | dosfstools (`mkfs.fat`, `fsck.fat`, `fatlabel`), mtools, fatresize (libparted) |
| exFAT | exfatprogs (`mkfs.exfat`, `fsck.exfat`, `exfatlabel`) |
| NTFS | ntfs-3g and ntfsprogs (`mkntfs`, `ntfsfix`, `ntfsresize`, `ntfsclone`, `ntfslabel`, `ntfsundelete`, `ntfsinfo`) |
| ext2/3/4 | e2fsprogs (`mke2fs`, `e2fsck`, `resize2fs`, `tune2fs`) |
| Partitions | util-linux `fdisk`, `sfdisk`, `wipefs`, `blkid`, `lsblk`, `partx`, `losetup`; parted; gptfdisk (`gdisk`, `sgdisk`) |
| Recovery | TestDisk (lost partitions, boot sectors) and PhotoRec (file carving) |
| Station install | `falcon-boot-mkstick32`, falcon-boot built static for i586 musl: puts falcon station-legacy on a disk; the station files come from the card |
| Cabinets | cabextract (9x `RB00x.CAB` registry backups) |
| Imaging | ddrescue, dd |

Decided against:

- **The kernel's ntfs3** in place of ntfs-3g. Smaller, but less trusted on a
  damaged volume, and a rescue image meets damaged volumes.
- **cryptsetup.** mkstick uses it for encrypted sticks, not for a legacy
  install onto a disk, and it brings device-mapper, json-c, popt and a crypto
  library: several MB for volumes these machines do not have (2026-09-27).

A full disk toolkit (2026-09-27): TestDisk and PhotoRec, left out on
2026-09-25, went in with fatresize, exfatprogs, gptfdisk, partx, losetup and
cabextract when the image became what installs falcon station-legacy onto a
machine's own disk. The tools sit in the compressed squashfs, so each costs
its compressed size in RAM, not its installed size.

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
`classic_defconfig`. A musl toolchain for i586,
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
4. **Real hardware**: the A21m, 2026-09-27, booted from a CF card through
   falcon. It found init spinning (32-bit time system calls missing), the
   power button and CF card unsupported, and read-write NTFS refused; all
   fixed in the kernel fragment.
5. **Networking**, in the same image (see "One image").
