$SolutionName = "MyApp"
$framework = "net8.0"
$pversion = "8.*"
$VendorName = "Home"
$IdentityRootName = "identity"
$identityRoot = ".\$($IdentityRootName)\"
$identitySolutionName = $SolutionName+'.Identity'
$identitySolutionFullName =$identitySolutionName+'.sln'

$identitySolutionPath = Join-Path $identityRoot $identitySolutionFullName
#powershell -ExecutionPolicy Bypass -File "main.ps1" *> $null
#. ".\backend-core.ps1"
#. ".\backend-test.ps1"
#. ".\frontend.ps1"
. ".\identity.ps1" 

Get-ChildItem * -Include Class1.cs -Recurse | Remove-Item
Get-ChildItem * -Include UnitTest1.cs -Recurse | Remove-Item

#dotnet clean ".\backend\$($SolutionName).sln"
#dotnet build ".\backend\$($SolutionName).sln" --configuration Release



dotnet clean $identitySolutionPath
dotnet build $identitySolutionPath --configuration Release

Write-Host "All done! The solution '$($identitySolutionPath)' has been created successfully."