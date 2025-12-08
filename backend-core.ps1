. ".\backend-core-functions.ps1"
if (Test-Path backend) { Remove-Item backend -Recurse -Force }
New-Item -ItemType Directory -Name backend
cd backend

if (Test-Path $SolutionName) { Remove-Item $SolutionName -Recurse -Force }
if (Test-Path "Core") { Remove-Item "Core" -Recurse -Force }
if (Test-Path "Infrastructure") { Remove-Item "Infrastructure" -Recurse -Force }
if (Test-Path "Presentation") { Remove-Item "Presentation" -Recurse -Force }
if (Test-Path "$($SolutionName).sln") { Remove-Item "$($SolutionName).sln" -Force }

dotnet new sln --name $SolutionName
New-Item -ItemType Directory -Name Core
New-Item -ItemType Directory -Name Infrastructure
New-Item -ItemType Directory -Name Presentation

dotnet new classlib --framework $framework --name "$($SolutionName).Domain" --output "Core\$($SolutionName).Domain"
dotnet new classlib --framework $framework --name "$($SolutionName).Application" --output "Core\$($SolutionName).Application"
dotnet new classlib --framework $framework --name "$($SolutionName).Persistence" --output "Infrastructure\$($SolutionName).Persistence"
dotnet new webapi --framework $framework --name "$($SolutionName).WebApi" --output "Presentation\$($SolutionName).WebApi"

dotnet sln add "Core\$($SolutionName).Domain\$($SolutionName).Domain.csproj"
dotnet sln add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj"
dotnet sln add "Infrastructure\$($SolutionName).Persistence\$($SolutionName).Persistence.csproj"
dotnet sln add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj"


# Application -> Domain
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" reference "Core\$($SolutionName).Domain\$($SolutionName).Domain.csproj"
# Persistence -> Domain
dotnet add "Infrastructure\$($SolutionName).Persistence\$($SolutionName).Persistence.csproj" reference "Core\$($SolutionName).Domain\$($SolutionName).Domain.csproj"
# Persistence -> Application
dotnet add "Infrastructure\$($SolutionName).Persistence\$($SolutionName).Persistence.csproj" reference "Core\$($SolutionName).Application\$($SolutionName).Application.csproj"
# WebApi -> Application
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" reference "Core\$($SolutionName).Application\$($SolutionName).Application.csproj"
# WebApi -> Persistence
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" reference "Infrastructure\$($SolutionName).Persistence\$($SolutionName).Persistence.csproj"



New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\Common\Behaviors"  -Force
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\Common\Exceptions" -Force
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\Common\Mappings" -Force
New-Item -ItemType Directory -Path "Core\$($SolutionName).Application\Interfaces" -Force


New-Item -ItemType Directory -Path "Infrastructure\$($SolutionName).Persistence\EntityTypeConfigurations" -Force
New-Item -ItemType Directory -Path "Presentation\$($SolutionName).WebApi\Controllers" -Force
New-Item -ItemType Directory -Path "Presentation\$($SolutionName).WebApi\Middleware" -Force
New-Item -ItemType Directory -Path "Presentation\$($SolutionName).WebApi\Models" -Force
New-Item -ItemType Directory -Path "Presentation\$($SolutionName).WebApi\Services" -Force


dotnet add "Infrastructure\$($SolutionName).Persistence\$($SolutionName).Persistence.csproj" package --framework $framework Microsoft.EntityFrameworkCore.Sqlite

dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package AutoMapper --version 12.0.1
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package --framework $framework FluentValidation
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package --framework $framework FluentValidation.DependencyInjectionExtensions
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package MediatR --version 11.1.0
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package MediatR.Extensions.Microsoft.DependencyInjection --version 11.1.0
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package --framework $framework    Microsoft.EntityFrameworkCore
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package --framework $framework    Serilog
dotnet add "Core\$($SolutionName).Application\$($SolutionName).Application.csproj" package --framework $framework    Serilog.Sinks.File


dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" package AutoMapper.Extensions.Microsoft.DependencyInjection  --version 12.0.1
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" package Microsoft.AspNetCore.Authentication.JwtBearer  --version 8.0.1
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" package --framework $framework Microsoft.AspNetCore.Mvc.Versioning
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" package --framework $framework Microsoft.AspNetCore.Mvc.Versioning.ApiExplorer
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" package --framework $framework Serilog.AspNetCore
dotnet add "Presentation\$($SolutionName).WebApi\$($SolutionName).WebApi.csproj" package --framework $framework Swashbuckle.AspNetCore

$models=  @(
   [PSCustomObject]@{
    ModelName = "Order"
    Fields = @([PSCustomObject]@{
        FieldName = "Id"
        FieldType = "Guid"
        Required = 1
		KeyField = 0
    },[PSCustomObject]@{
        FieldName = "Title"
        FieldType = "string"
        Required = 1
		KeyField = 0
   })
   },
	[PSCustomObject]@{
    ModelName = "Contragent"
    Fields = @(
	   [PSCustomObject]@{
        FieldName = "Id"
        FieldType = "Guid"
        Required = 1
		KeyField = 1
    },[PSCustomObject]@{
        FieldName = "Title"
        FieldType = "string"
        Required = 1
		KeyField = 0
    })
   }
 
)



#Common
Create-Common-Files 

$ModelList = [System.Collections.Generic.List[string]]@()
#Models
Create-Model-Files -models $models

foreach ($model in $models) {
	 Write-Host "Модель: $($model.ModelName)"
	$ModelList.Add($model.ModelName) 


#WebApi
Create-WebApi-Files -ModelName $model.ModelName	 
	 
	foreach ($field in $model.Fields) {
    Write-Host "Имя: $($field.FieldName), Модель: $($model.ModelName)"
	}
}

#Persistence
Create-Persistence-Files -ModelList $ModelList
cd ..

Write-Host "backend core '$($SolutionName)' "