@model {{Namespace}}.Models.EditApplicationViewModel

@{
    ViewData["Title"] = "Редактирование приложения";
}

<div class="container mt-4">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-sm border-warning">
                <div class="card-header bg-warning text-dark">
                    <h4 class="mb-0">✏️ Редактирование: @Model.DisplayName</h4>
                </div>
                <div class="card-body">
                    <form asp-action="Edit" method="post">
                        <input type="hidden" asp-for="Id" />
                        
                        <div asp-validation-summary="ModelOnly" class="alert alert-danger"></div>

                        <div class="row mb-3">
                            <div class="col-md-6">
                                <label asp-for="ClientId" class="form-label fw-bold"></label>
                                <input asp-for="ClientId" class="form-control" readonly disabled />
                                <div class="form-text">Client ID изменять нельзя.</div>
                            </div>
                            <div class="col-md-6">
                                <label asp-for="Type" class="form-label fw-bold">Тип клиента</label>
                                <select asp-for="Type" class="form-select">
                                    <option value="confidential">Confidential (Веб-сервер)</option>
                                    <option value="public">Public (SPA/Mobile)</option>
                                </select>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label asp-for="DisplayName" class="form-label fw-bold"></label>
                            <input asp-for="DisplayName" class="form-control" />
                            <span asp-validation-for="DisplayName" class="text-danger"></span>
                        </div>

                        <div class="mb-3">
                            <label asp-for="ClientSecret" class="form-label fw-bold"></label>
                            <input asp-for="ClientSecret" class="form-control" type="password" autocomplete="new-password" placeholder="Введите, чтобы сменить пароль" />
                            <div class="form-text text-muted">Оставьте пустым, если не хотите менять текущий секрет.</div>
                            <span asp-validation-for="ClientSecret" class="text-danger"></span>
                        </div>

                        <div class="mb-4">
                            <label asp-for="RedirectUri" class="form-label fw-bold"></label>
                            <input asp-for="RedirectUri" class="form-control" />
                            <span asp-validation-for="RedirectUri" class="text-danger"></span>
                        </div>

                        <div class="d-flex justify-content-between">
                            <a asp-action="Index" class="btn btn-outline-secondary">Отмена</a>
                            <button type="submit" class="btn btn-warning px-4">Сохранить изменения</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

@section Scripts {
    @{await Html.RenderPartialAsync("_ValidationScriptsPartial");}
}