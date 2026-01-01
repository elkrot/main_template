param(
    [Parameter(Mandatory)]
    [string]$TemplateRoot,

    [Parameter(Mandatory)]
    [string]$TargetRoot,

    [Parameter(Mandatory)]
    [string]$Namespace
)
Get-ChildItem $TemplateRoot -Recurse  -File |
    Where-Object {
        $_.Name -like '*.cs.tpl' -or
		$_.Name -like '*.cshtml.tpl' -or
		$_.Name -like '*.cshtml.tpl' -or
		$_.Name -like 'app.css.tpl' -or
        $_.Name -like 'appsettings.json.tpl'
    } | ForEach-Object {

    # относительный путь
    $relativePath = $_.FullName.Substring($TemplateRoot.Length)
	
	
#Write-Host $relativePath

    $targetPath   = Join-Path $TargetRoot $relativePath.Replace(".tpl","")

    # папка назначения
    $targetDir = Split-Path $targetPath
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    # обработка шаблона
    $content = Get-Content $_.FullName -Raw
	
	$replacements = @{
    Namespace = $Namespace
    Layer     = "Controllers"
    ClassName = "UserController"
}

foreach ($key in $replacements.Keys) {
    $content = $content -replace "\{\{$key\}\}", $replacements[$key]
}
    Set-Content -Path $targetPath -Value $content -Encoding UTF8
}
