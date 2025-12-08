$models=  @(
   [PSCustomObject]@{
    ModelName = "Order"
    Fields = @([PSCustomObject]@{
        FieldName = "Id"
        FieldType = "Int"
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
    ModelName = "User"
    Fields = @(
	   [PSCustomObject]@{
        FieldName = "Id"
        FieldType = "Int"
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

foreach ($model in $models) {
	 Write-Host "Модель: $($model.ModelName)"
	foreach ($field in $model.Fields) {
    Write-Host "Имя: $($field.FieldName), Модель: $($model.ModelName)"
	}
}


Write-Host "All done! The solution '$($SolutionName).sln' has been created successfully."

