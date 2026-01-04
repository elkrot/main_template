@{
    ViewData["Title"] = "Главная";
}

<div class="container text-center mt-5">
    <div class="jumbotron bg-light p-5 rounded-3 border">
        <h1 class="display-4">🔐 Auth Server</h1>
        <p class="lead">Сервер авторизации на базе OpenIddict и ASP.NET Core Identity.</p>
        <hr class="my-4">
        
        <p>Это административная панель. Для доступа к управлению необходимо авторизоваться.</p>

        <div class="mt-4">
            @* Проверяем, аутентифицирован ли пользователь через Cookie *@
            @if (User.Identity?.IsAuthenticated == true)
            {
                <div class="alert alert-success d-inline-block px-4">
                    👋 Привет, <strong>@User.Identity.Name</strong>!
                </div>
                
                <div class="mt-3 d-flex justify-content-center gap-3">
                    @* Ссылка на управление профилем *@
                    <a class="btn btn-primary btn-lg" asp-area="Identity" asp-page="/Account/Manage/Index">
                        ⚙️ Личный кабинет
                    </a>

                    @* Кнопка выхода (Logout выполняется через POST для безопасности) *@
                    <form class="form-inline" asp-area="Identity" asp-page="/Account/Logout" asp-route-returnUrl="@Url.Action("Index", "Home", new { area = "" })">
                        <button type="submit" class="btn btn-outline-danger btn-lg">Выход</button>
                    </form>
                </div>
            }
            else
            {
                @* Если пользователь гость - показываем кнопки входа и регистрации *@
                <div class="d-grid gap-2 d-sm-flex justify-content-sm-center">
                    <a class="btn btn-primary btn-lg px-4 gap-3" asp-area="Identity" asp-page="/Account/Login">
                        Войти в систему
                    </a>
                    
                    <a class="btn btn-outline-secondary btn-lg px-4" asp-area="Identity" asp-page="/Account/Register">
                        Регистрация
                    </a>
                </div>
                <p class="text-muted mt-3 small">Используйте учетную запись администратора для настройки клиентов.</p>
            }
        </div>
    </div>
</div>