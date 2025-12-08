if ( Test-Path frontend ) { Remove-Item frontend -Recurse -Force }
New-Item -ItemType Directory -Name frontend
cd frontend

cd ..
Write-Host "frontend."