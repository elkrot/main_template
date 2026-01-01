param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SolutionName,

    [Parameter(Mandatory)]
    [ValidateSet("net6.0","net7.0","net8.0")]
    [string]$framework,
	
	[Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$pversion,
	
	[Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VendorName
)

#Identity
$oiversion = "7.*"
$IdentityRootName = "identity"
$identityRoot = ".\$($IdentityRootName)\"
$identitySolutionName = $SolutionName+'.Identity'
$identitySolutionFullName =$identitySolutionName+'.sln'
$identitySolutionPath = Join-Path $identityRoot $identitySolutionFullName

if (Test-Path $IdentityRootName) { Remove-Item $IdentityRootName -Recurse -Force }
New-Item -ItemType Directory -Name $IdentityRootName
cd $IdentityRootName
$identitySolutionProjName =$identitySolutionName+'.csproj'
$identitySolutionFulPath ='.\'+$identitySolutionName
$identitySolutionFulName=$identitySolutionFulPath+'.sln'
$identitySolutionProjPath = Join-Path $identitySolutionFulPath  $identitySolutionProjName

dotnet new sln --name $identitySolutionName
dotnet new web --framework $framework --name $identitySolutionName --output $identitySolutionName
dotnet sln $identitySolutionFulName add $identitySolutionProjPath

..\generate.ps1 `
  -TemplateRoot "D:\repos\1. new_super_project\main_template-main\identity_template"`
  -TargetRoot $identitySolutionName `
  -Namespace $identitySolutionName


dotnet dev-certs https --trust

#openidict

dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.Server.AspNetCore --version $oiversion
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.AspNetCore --version $oiversion
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.Core --version $oiversion
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.EntityFrameworkCore --version $oiversion
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.Validation.AspNetCore --version $oiversion

#openidict

dotnet add $identitySolutionProjPath package Microsoft.AspNetCore.Identity.EntityFrameworkCore --version $pversion
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore --version $pversion
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore.Design --version $pversion
dotnet add $identitySolutionProjPath package Microsoft.EntityFrameworkCore.Sqlite --version $pversion



dotnet add $identitySolutionProjPath package --framework $framework Microsoft.VisualStudio.Web.CodeGeneration.Design --version $pversion
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore.Design --version $pversion

dotnet add $identitySolutionProjPath package --framework $framework Microsoft.AspNetCore.Identity.UI --version $pversion
#dotnet add $identitySolutionProjPath package Microsoft.EntityFrameworkCore.SqlServer
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore.Tools --version $pversion







#DotnetEnv ,вставлять куски файлов в основной файл
dotnet tool uninstall --global dotnet-ef
dotnet tool uninstall -g dotnet-aspnet-codegenerator

dotnet tool install -g dotnet-aspnet-codegenerator --version $pversion
dotnet tool install --global dotnet-ef --version $pversion

cd $identitySolutionName
dotnet aspnet-codegenerator identity -dc $identitySolutionName.Identity.Data.AuthDbContext --files "Account.Register;Account.Login;Account.Logout"
#dotnet aspnet-codegenerator identity -lf --project $identitySolutionName
dotnet ef migrations add CreateIdentitySchema
dotnet ef database update

Write-Host  $identitySolutionName
cd ..

cd ..

dotnet clean $identitySolutionPath
dotnet build $identitySolutionPath --configuration Release
Write-Host "All done! The solution '$($SolutionName).sln' has been created successfully."
#dotnet run --launch-profile "https"