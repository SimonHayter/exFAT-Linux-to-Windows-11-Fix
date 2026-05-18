# exFAT Linux to Windows 11 Fix

## The Problem

You've stress-tested your drive with **F3write** and **F3read** using Parted Magic or another Linux-based tool, formatted it as exFAT, and plugged it back into Windows — only for it to show up as blank, unformatted, or completely invisible. The drive is fine. The filesystem is intact. Windows just refuses to recognise it.

The culprit is a partition type ID mismatch. Linux disk utilities assign a partition identifier that Windows doesn't associate with a valid exFAT volume. The fix doesn't require reformatting or any data loss — just a single metadata correction.

---

## The Fix

This PowerShell script uses `diskpart` to reset the partition type ID to `0x07`, the value Windows expects for exFAT and NTFS volumes. Once corrected, Windows immediately recognises the drive and mounts it normally.

### Windows Compatibility

The script is compatible with:

- Windows 7
- Windows 8 / 8.1
- Windows 10
- Windows 11

> **Not supported on Windows XP or Vista.**

---

## Usage

### Downloading the Script

Download `exFAT-fix.ps1` from this repository and save it anywhere convenient — your Desktop or Downloads folder is perfectly fine. This is a one-off fix script and doesn't need to be installed anywhere specific.

### Running the Script

> **Warning:** Always confirm your disk and partition numbers before running. Use **Disk Management** or run `list disk` inside diskpart to verify.

**Step 1** — If you have never run a PowerShell script before, you may need to enable them first. Run this once in PowerShell:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

> This allows locally saved scripts to run freely. You will only need to do this once.

**Step 2** — Right-click PowerShell and select **Run as Administrator**, navigate to where you saved the script, then run it using the `.\` prefix:

```powershell
.\exFAT-fix.ps1
```

### Reading the Partition Colours

When the script lists partitions on your selected disk, each row is colour-coded to help you identify the right one:

| Colour | Meaning |
|--------|---------|
| 🟢 Green | exFAT filesystem, no drive letter assigned — prime candidate to fix |
| 🟡 Yellow | exFAT filesystem, but already has a drive letter — Windows can see it, may not need fixing |
| 🔴 Red | Not exFAT (NTFS, FAT32, system partitions, etc.) — leave alone |

> **Note:** If Windows cannot read the partition at all due to the ID mismatch, it may show the filesystem as `Unknown` with no drive letter. These are also highlighted green as they are likely the broken exFAT partition.

### Quick Command Alternative

If you already know your disk and partition numbers — for example, you only have one fixed internal drive and any new drive will always land on the same disk number — you can skip the script entirely and paste the following directly into PowerShell:

```powershell
"select disk 1","select partition 1","set id=07 override","exit" | diskpart
```

> **Before running, update `disk 1` and `partition 1` to match your setup.** This is best suited for predictable, consistent configurations where the target disk number doesn't change between uses.

---

## License

MIT

---

## Disclaimer

This script is intended for use on freshly formatted mechanical drives, solid state drives, and flash drives that have not yet been populated with data. If you intend to run this script on a drive that contains valuable content, you should first clone the drive using one of the many tools available online before proceeding.

This script modifies low-level disk partition data. While it is designed only to correct a partition type ID and should not affect your data, incorrect use — such as targeting the wrong disk or partition — can result in permanent, unrecoverable data loss. Always back up any important data before proceeding. Use this script entirely at your own risk. The author accepts no responsibility for any data loss, corruption, or damage resulting from its use.
