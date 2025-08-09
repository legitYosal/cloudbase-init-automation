function Log-Message {
    param ([string]$Message)
    Write-Host $Message
}

try {
    $service = Get-Service -Name "cloudbase-init" -ErrorAction SilentlyContinue
    if ($service) {
        Log-Message "Cloudbase-Init is already installed. Status: $($service.Status), StartType: $($service.StartType)"
        exit 0
    }
    Log-Message "Cloudbase-Init not found. Proceeding with installation."

    $arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
    Log-Message "Detected architecture: $arch"

    if ($arch -eq "64-bit") {
        $msiUrl = "https://www.cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi"
    } elseif ($arch -eq "32-bit") {
        $msiUrl = "https://www.cloudbase.it/downloads/CloudbaseInitSetup_Stable_x86.msi"
    } else {
        Log-Message "Unsupported architecture: $arch"
        exit 1
    }

    try {
        $headResponse = Invoke-WebRequest -Uri $msiUrl -Method Head -UseBasicParsing
        if ($headResponse.StatusCode -eq 200) {
            $fileSize = $headResponse.Headers['Content-Length']
            if ($fileSize) {
                $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
                Log-Message "MSI file exists at $msiUrl. Size: $fileSizeMB MB. Proceeding to download."
            } else {
                Log-Message "MSI file exists at $msiUrl, but size unknown. Proceeding to download."
            }
        } else {
            Log-Message "HEAD request failed with status: $($headResponse.StatusCode)"
            exit 1
        }
    } catch {
        Log-Message "Error checking MSI: $($_.Exception.Message). Check if URL is valid or registration is needed."
        exit 1
    }

    $downloadDir = "$env:USERPROFILE\Downloads"
    $msiPath = "$downloadDir\CloudbaseInstaller.msi"
    Log-Message "Downloading MSI from $msiUrl to $msiPath..."
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
    Log-Message "Download complete."

    $installLog = "$downloadDir\install.log"
    Log-Message "Starting silent installation. Log file: $installLog"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /l*v `"$installLog`"" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -eq 0) {
        Log-Message "Installation completed successfully."
    } else {
        Log-Message "Installation failed with exit code: $($process.ExitCode). Check $installLog for details."
        exit 1
    }

    $service = Get-Service -Name "cloudbase-init" -ErrorAction SilentlyContinue
    if ($service) {
        Log-Message "Installation verified. Cloudbase-Init service: Name=$($service.Name), Status=$($service.Status), StartType=$($service.StartType)"
        # Optional: Start the service if not running
        # if ($service.Status -ne "Running") { Start-Service -Name "cloudbase-init" }
    } else {
        Log-Message "Verification failed: Service not found after installation."
        exit 1
    }

    Log-Message "All steps completed successfully."

}
catch {
    Log-Message "Unexpected error: $($_.Exception.Message)"
    exit 1
}
