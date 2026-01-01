$SolutionName = "MyApp"
$framework = "net8.0"
$pversion = "8.*"
$VendorName = "Home"



#powershell -ExecutionPolicy Bypass -File "main.ps1" *> $null
#. ".\backend-core.ps1"
#. ".\backend-test.ps1"
#. ".\frontend.ps1"
. ".\identity.ps1"  -SolutionName $SolutionName -framework $framework -pversion $pversion -VendorName $VendorName

Get-ChildItem * -Include Class1.cs -Recurse | Remove-Item
Get-ChildItem * -Include UnitTest1.cs -Recurse | Remove-Item

#dotnet clean ".\backend\$($SolutionName).sln"
#dotnet build ".\backend\$($SolutionName).sln" --configuration Release





Write-Host "All done! The solution '$($identitySolutionPath)' has been created successfully."