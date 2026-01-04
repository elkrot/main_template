@model IEnumerable<{{Namespace}}.Models.ApplicationViewModel>

@{
    ViewData["Title"] = "Список приложений";
}

<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>📂 Зарегистрированные приложения</h2>
        @* Задел на будущее: кнопка создания *@
		<a asp-action="Create" class="btn btn-success">
			+ Добавить приложение
		</a>
    </div>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <table class="table table-hover table-striped mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Display Name</th>
                        <th>Client ID</th>
                        <th>Type</th>
                        <th>Redirect URIs</th>
                        <th class="text-end">Действия</th>
                    </tr>
                </thead>
                <tbody>
                    @if (!Model.Any())
                    {
                        <tr>
                            <td colspan="5" class="text-center py-4 text-muted">
                                Приложений не найдено.
                            </td>
                        </tr>
                    }
                    else
                    {
                        @foreach (var app in Model)
                        {
                            <tr>
                                <td class="fw-bold">
                                    @* Если имя пустое, показываем заглушку *@
                                    @(app.DisplayName ?? "— без имени —")
                                </td>
                                <td>
                                    <code class="text-primary">@app.ClientId</code>
                                </td>
                                <td>
                                    <span class="badge bg-secondary">@app.Type</span>
                                </td>
                                <td class="small text-muted">
                                    @if(string.IsNullOrEmpty(app.RedirectUris)) {
                                        <span>—</span>
                                    } else {
                                        @app.RedirectUris
                                    }
                                </td>
                                <td class="text-end">
									@* Передаем ID приложения в метод Edit *@
									<a asp-action="Edit" asp-route-id="@app.Id" class="btn btn-sm btn-outline-primary">
										✏️ Ред.
									</a>
								</td>
                            </tr>
                        }
                    }
                </tbody>
            </table>
        </div>
    </div>
</div>