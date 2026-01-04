@model {{Namespace}}.Models.CreateApplicationViewModel

@{
    ViewData["Title"] = "Новое приложение";
}

<div class="container mt-4">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">➕ Регистрация нового приложения</h4>
                </div>
                <div class="card-body">
                    <form asp-action="Create" method="post">
                        
                        @* Вывод общих ошибок *@
                        <div asp-validation-summary="ModelOnly" class="alert alert-danger" role="alert"></div>

                        <div class="mb-3">
                            <label asp-for="DisplayName" class="form-label fw-bold"></label>
                            <input asp-for="DisplayName" class="form-control" placeholder="Например: Мой Интернет Магазин" />
                            <span asp-validation-for="DisplayName" class="text-danger"></span>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label asp-for="ClientId" class="form-label fw-bold"></label>
                                <input asp-for="ClientId" class="form-control" placeholder="client-id" />
                                <div class="form-text">Уникальный ID, латиница.</div>
                                <span asp-validation-for="ClientId" class="text-danger"></span>
                            </div>

                            <div class="col-md-6 mb-3">
                                <label asp-for="ClientSecret" class="form-label fw-bold"></label>
                                <input asp-for="ClientSecret" class="form-control" type="password" autocomplete="new-password" placeholder="Придумайте сложный пароль" />
                                <div class="form-text">Оставьте пустым для публичных клиентов (SPA/Mobile).</div>
                                <span asp-validation-for="ClientSecret" class="text-danger"></span>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label asp-for="RedirectUri" class="form-label fw-bold"></label>
                            <input asp-for="RedirectUri" class="form-control" placeholder="https://myapp.com/callback" />
                            <div class="form-text">URL, куда вернется пользователь после логина.</div>
                            <span asp-validation-for="RedirectUri" class="text-danger"></span>
                        </div>
                        
                        <div class="mb-4">
                            <label asp-for="Type" class="form-label fw-bold">Тип клиента</label>
                            <select asp-for="Type" class="form-select">
                                <option value="confidential">Confidential (Веб-сервер, есть Secret)</option>
                                <option value="public">Public (SPA, Mobile, без Secret)</option>
                            </select>
                        </div>

                        <div class="d-flex justify-content-between">
                            <a asp-action="Index" class="btn btn-outline-secondary">← Назад к списку</a>
                            <button type="submit" class="btn btn-success px-4">Создать приложение</button>
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