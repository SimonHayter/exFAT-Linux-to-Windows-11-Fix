if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Right-click PowerShell and select 'Run as Administrator'."
    exit 1
}

Write-Host "`nAvailable Disks:" -ForegroundColor Cyan
Get-Disk | Select-Object Number, FriendlyName, OperationalStatus, @{Name="Size (GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}} | Format-Table -AutoSize

$diskNum = Read-Host "Enter the disk number you wish to fix"

if ($diskNum -notmatch '^\d+$' -or -not (Get-Disk -Number $diskNum -ErrorAction SilentlyContinue)) {
    Write-Error "Disk '$diskNum' not found. Please check the number and try again."
    exit 1
}

Write-Host "`nPartitions on Disk $diskNum:" -ForegroundColor Cyan
Write-Host ("{0,-6} {1,-20} {2,-10} {3,-12} {4}" -f "No.", "Type", "Size (GB)", "FileSystem", "DriveLetter")
Write-Host ("{0,-6} {1,-20} {2,-10} {3,-12} {4}" -f "---", "----", "---------", "----------", "-----------")

foreach ($part in Get-Partition -DiskNumber $diskNum) {
    $volume = Get-Volume -Partition $part -ErrorAction SilentlyContinue
    $fs     = if ($volume) { $volume.FileSystemType } else { "Unknown" }
    $letter = if ($part.DriveLetter) { "$($part.DriveLetter):" } else { "None" }
    $size   = [math]::Round($part.Size / 1GB, 2)

    $isExFAT   = $fs -eq "exFAT"
    $hasLetter = $part.DriveLetter -as [bool]

    $color = if ($isExFAT -and -not $hasLetter) {
        "Green"   # exFAT, no letter - likely the broken partition
    } elseif ($isExFAT -and $hasLetter) {
        "Yellow"  # exFAT but Windows already sees it
    } elseif (-not $hasLetter -and $fs -eq "Unknown") {
        "Green"   # no letter, unreadable - could be broken exFAT
    } else {
        "Red"     # NTFS, FAT32, system partitions, etc.
    }

    Write-Host ("{0,-6} {1,-20} {2,-10} {3,-12} {4}" -f $part.PartitionNumber, $part.Type, $size, $fs, $letter) -ForegroundColor $color
}

Write-Host ""
Write-Host "  Green  = exFAT, no drive letter — likely needs fixing" -ForegroundColor Green
Write-Host "  Yellow = exFAT, drive letter assigned — Windows can already see it" -ForegroundColor Yellow
Write-Host "  Red    = Not exFAT — leave alone" -ForegroundColor Red
Write-Host ""

$partNum = Read-Host "Enter the partition number you wish to fix"

if ($partNum -notmatch '^\d+$' -or -not (Get-Partition -DiskNumber $diskNum -PartitionNumber $partNum -ErrorAction SilentlyContinue)) {
    Write-Error "Partition '$partNum' not found on Disk $diskNum."
    exit 1
}

Write-Host "`nYou are about to modify Disk $diskNum, Partition $partNum." -ForegroundColor Yellow
$confirm = Read-Host "Type YES to confirm"

if ($confirm -ne "YES") {
    Write-Host "Operation cancelled." -ForegroundColor DarkGray
    exit 0
}

$commands = @"
select disk $diskNum
select partition $partNum
set id=07 override
exit
"@

$commands | diskpart

Write-Host "`nDone. Safely eject and reconnect the drive — Windows should now recognise it." -ForegroundColor Green
