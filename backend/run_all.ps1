$ErrorActionPreference = "Stop"

Write-Host "Running setup_models.py..."
python setup_models.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "setup_models.py failed. Exiting."
    exit $LASTEXITCODE
}

# Write-Host "Running export_onnx.py..."
# python scripts\export_onnx.py
#
# if ($LASTEXITCODE -ne 0) {
#     Write-Host "export_onnx.py failed. Exiting."
#     exit $LASTEXITCODE
# }

Write-Host "Starting backend server..."
python main.py
