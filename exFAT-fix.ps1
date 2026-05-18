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

Write-Host "`nPartitions on Disk ${diskNum}:" -ForegroundColor Cyan
Get-Partition -DiskNumber $diskNum | Select-Object PartitionNumber, Type,
    @{Name="Size (GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}},
    @{Name="FileSystem"; Expression={$v = Get-Volume -Partition $_ -ErrorAction SilentlyContinue; if ($v) { $v.FileSystemType } else { "Unknown" }}},
    DriveLetter | Format-Table -AutoSize

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

Write-Host "`nDone. Safely eject and reconnect the drive - Windows should now recognise it." -ForegroundColor Green
