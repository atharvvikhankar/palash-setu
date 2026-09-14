$ErrorActionPreference = "Stop"

$Url = "https://aka.ms/vs/17/release/vs_buildtools.exe"
$OutPath = "$env:TEMP\vs_buildtools.exe"

Write-Host "Downloading vs_buildtools.exe from Microsoft..."
Invoke-WebRequest -Uri $Url -OutFile $OutPath

Write-Host "Triggering installation..."
Write-Host "NOTE: A User Account Control (UAC) prompt will appear. Please click 'Yes' to allow the installation."
Write-Host "The installation will run silently in the background and may take 5-10 minutes to complete."

$ProcessArgs = "--quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

# Let the executable trigger the UAC prompt natively
$Process = Start-Process -FilePath $OutPath -ArgumentList $ProcessArgs -Wait -PassThru

if ($Process.ExitCode -eq 0 -or $Process.ExitCode -eq 3010) {
    Write-Host "C++ Build Tools successfully installed!"
} else {
    Write-Host "Installation failed or was cancelled. Exit code: $($Process.ExitCode)"
    exit 1
}
