# =====================================================
# Burp Suite Full Setup Script
# =====================================================

$ProgressPreference = 'SilentlyContinue'

# -----------------------------------------------------
# Paths
# -----------------------------------------------------
$downloaderDir = "C:\Downloader"
$burpDir       = "C:\burp"
$jdkInstaller  = "$downloaderDir\jdk21.exe"
$burpJar       = "$downloaderDir\burpsuite.jar"
$batFile       = "$burpDir\Burp.bat"
$desktopLink   = "$([Environment]::GetFolderPath('Desktop'))\BurpSuite.lnk"

# -----------------------------------------------------
# Create Folders
# -----------------------------------------------------
New-Item -ItemType Directory -Path $downloaderDir -Force | Out-Null
New-Item -ItemType Directory -Path $burpDir -Force | Out-Null

Write-Host "[+] Downloader folder: $downloaderDir"
Write-Host "[+] Burp folder: $burpDir"

# -----------------------------------------------------
# Download Java JDK 21 (if not installed)
# -----------------------------------------------------
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "[+] Downloading Java JDK 21..."
    Invoke-WebRequest `
        -Uri "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.exe" `
        -OutFile $jdkInstaller

    Write-Host "[+] Installing Java JDK 21..."
    Start-Process $jdkInstaller "/s" -Wait
}
else {
    Write-Host "[+] Java already installed"
}

# -----------------------------------------------------
# Download Burp Suite (Official Latest)
# -----------------------------------------------------
Write-Host "[+] Downloading Burp Suite (Official)..."
Invoke-WebRequest `
    -Uri "https://portswigger.net/burp/releases/download?product=pro&type=Jar" `
    -OutFile $burpJar

# -----------------------------------------------------
# Move Files to Burp Folder
# -----------------------------------------------------
Write-Host "[+] Moving files to burp folder..."
Move-Item "$downloaderDir\*" $burpDir -Force

# -----------------------------------------------------
# Set JAVA_HOME + PATH (ALL USERS)
# -----------------------------------------------------
$javaHome = Get-ChildItem "C:\Program Files\Java" -Directory |
            Sort-Object Name -Descending |
            Select-Object -First 1

if ($javaHome) {
    Write-Host "[+] Setting JAVA_HOME for all users..."
    [Environment]::SetEnvironmentVariable(
        "JAVA_HOME",
        $javaHome.FullName,
        "Machine"
    )

    Write-Host "[+] Updating PATH for all users..."
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -notlike "*$($javaHome.FullName)\bin*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$machinePath;$($javaHome.FullName)\bin",
            "Machine"
        )
    }
}

# -----------------------------------------------------
# Reload Environment (Current Session)
# -----------------------------------------------------
$env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine")

# -----------------------------------------------------
# Create BAT Launcher
# -----------------------------------------------------
$batContent = @"
@echo off
cd /d "%~dp0"
java -jar "burpsuite.jar"
"@

Set-Content -Path $batFile -Value $batContent -Encoding ASCII
Write-Host "[+] Burp.bat created"

# -----------------------------------------------------
# Create Desktop Shortcut
# -----------------------------------------------------
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($desktopLink)

$shortcut.TargetPath = $batFile
$shortcut.WorkingDirectory = $burpDir
$shortcut.WindowStyle = 1
$shortcut.Description = "Burp Suite Launcher"

$shortcut.Save()
Write-Host "[+] Desktop shortcut created"

# -----------------------------------------------------
# Launch Burp
# -----------------------------------------------------
Write-Host "[+] Launching Burp Suite..."
Start-Process $batFile
