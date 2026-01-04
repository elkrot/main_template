<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - Auth Server</title>
    
    <!-- Подключение Bootstrap (стандартное для шаблона MVC) -->
    <link rel="stylesheet" href="~/lib/bootstrap/dist/css/bootstrap.min.css" />
    <link rel="stylesheet" href="~/css/site.css" asp-append-version="true" />
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-sm navbar-toggleable-sm navbar-light bg-white border-bottom box-shadow mb-3">
            <div class="container-fluid">
                <!-- Логотип / Название -->
                <a class="navbar-brand" asp-area="" asp-controller="Home" asp-action="Index">🔐 AuthServer</a>
                
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target=".navbar-collapse" aria-controls="navbarSupportedContent"
                        aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                
                <div class="navbar-collapse collapse d-sm-inline-flex justify-content-between">
                    <!-- Левая часть меню -->
                    <ul class="navbar-nav flex-grow-1">
                        <li class="nav-item">
                            <a class="nav-link text-dark" asp-area="" asp-controller="Home" asp-action="Index">Главная</a>
                        </li>
                        
                        <!-- Ссылка на Приложения (видна только авторизованным) -->
                        @if (User.Identity?.IsAuthenticated == true)
                        {
                            <li class="nav-item">
                                <a class="nav-link text-dark fw-bold" asp-area="" asp-controller="Clients" asp-action="Index">📂 Приложения</a>
                            </li>
                        }
                    </ul>
                    
                    <!-- Правая часть меню: Вход / Регистрация / Профиль -->
                    <!-- Это частичное представление генерируется Identity -->
                    <partial name="_LoginPartial" />
                </div>
            </div>
        </nav>
    </header>
    
    <div class="container">
        <main role="main" class="pb-3">
            <!-- Сюда подставляется содержимое конкретной страницы -->
            @RenderBody()
        </main>
    </div>

    <footer class="border-top footer text-muted">
        <div class="container">
            &copy; 2024 - OpenIddict Auth Server - <a asp-area="" asp-controller="Home" asp-action="Privacy">Privacy</a>
        </div>
    </footer>

    <!-- Скрипты -->
    <script src="~/lib/jquery/dist/jquery.min.js"></script>
    <script src="~/lib/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
    <script src="~/js/site.js" asp-append-version="true"></script>
    
    <!-- Секция для скриптов, подключаемых на конкретных страницах -->
    @await RenderSectionAsync("Scripts", required: false)
</body>
</html>