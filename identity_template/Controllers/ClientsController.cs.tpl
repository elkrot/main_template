using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OpenIddict.Abstractions;
using {{Namespace}}.Models;
using System.Text.Json;
using static OpenIddict.Abstractions.OpenIddictConstants;


namespace {{Namespace}}.Controllers
{
    [Authorize] // Доступ только для авторизованных администраторов
    public class ClientsController : Controller
    {
        private readonly IOpenIddictApplicationManager _manager;

        public ClientsController(IOpenIddictApplicationManager manager)
        {
            _manager = manager;
        }

        public async Task<IActionResult> Index(CancellationToken cancellationToken)
        {
            var applications = new List<ApplicationViewModel>();

            // manager.ListAsync() возвращает IAsyncEnumerable
            await foreach (var app in _manager.ListAsync(count: null, offset: null, cancellationToken))
            {
                // Извлекаем данные, используя методы менеджера (абстракция от конкретной БД)
                var descriptor = new ApplicationViewModel
                {
                    Id = await _manager.GetIdAsync(app, cancellationToken),
                    ClientId = await _manager.GetClientIdAsync(app, cancellationToken),
                    DisplayName = await _manager.GetDisplayNameAsync(app, cancellationToken),
                    Type = await _manager.GetClientTypeAsync(app, cancellationToken),
                    
                    // URI возвращаются как коллекция, объединим их для вывода
                    RedirectUris = string.Join(", ", await _manager.GetRedirectUrisAsync(app, cancellationToken))
                };

                applications.Add(descriptor);
            }

            return View(applications);
        }
		
		
		// 1. Отображение формы
        [HttpGet]
        public IActionResult Create()
        {
            return View(new CreateApplicationViewModel());
        }

        // 2. Обработка формы
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CreateApplicationViewModel model, CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            // Проверяем, не занят ли ClientId
            if (await _manager.FindByClientIdAsync(model.ClientId, cancellationToken) != null)
            {
                ModelState.AddModelError("ClientId", "Такой Client ID уже существует.");
                return View(model);
            }

            var descriptor = new OpenIddictApplicationDescriptor
            {
                ClientId = model.ClientId,
                DisplayName = model.DisplayName,
                ClientType = model.Type,
                // Если тип confidential, то Secret обязателен (менеджер сам его захэширует)
                ClientSecret = model.Type == ClientTypes.Confidential ? model.ClientSecret : null,
                
                // Права доступа (Permissions).
                // Для простоты даем стандартный набор прав для Web-приложения + API
                Permissions =
                {
                    Permissions.Endpoints.Authorization,
                    Permissions.Endpoints.Token,
                    Permissions.Endpoints.Revocation,
                    Permissions.Endpoints.Introspection, // Для проверки токена API ресурсом

                    Permissions.GrantTypes.AuthorizationCode,
                    Permissions.GrantTypes.ClientCredentials,
                    Permissions.GrantTypes.RefreshToken,

                    Permissions.ResponseTypes.Code,
                    
                    Permissions.Scopes.Email,
                    Permissions.Scopes.Profile,
                    Permissions.Scopes.Roles
                }
            };

            // Добавляем Redirect URI, если указан
            if (!string.IsNullOrEmpty(model.RedirectUri))
            {
                descriptor.RedirectUris.Add(new Uri(model.RedirectUri));
            }

            try 
            {
                await _manager.CreateAsync(descriptor, cancellationToken);
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                ModelState.AddModelError(string.Empty, $"Ошибка создания: {ex.Message}");
                return View(model);
            }
        }
		
		// ... (после методов Create)

        // 3. Страница редактирования
        [HttpGet]
        public async Task<IActionResult> Edit(string id, CancellationToken cancellationToken)
        {
            var app = await _manager.FindByIdAsync(id, cancellationToken);
            if (app == null)
            {
                return NotFound();
            }

            // Загружаем данные из БД в модель
            var model = new EditApplicationViewModel
            {
                Id = await _manager.GetIdAsync(app, cancellationToken),
                ClientId = await _manager.GetClientIdAsync(app, cancellationToken),
                DisplayName = await _manager.GetDisplayNameAsync(app, cancellationToken),
                Type = await _manager.GetClientTypeAsync(app, cancellationToken),
                // Преобразуем список URI в строку
                RedirectUri = string.Join(", ", await _manager.GetRedirectUrisAsync(app, cancellationToken))
            };

            return View(model);
        }

        // 4. Обработка изменений
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(EditApplicationViewModel model, CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            // 1. Находим приложение в БД
            var app = await _manager.FindByIdAsync(model.Id, cancellationToken);
            if (app == null)
            {
                return NotFound();
            }

            // 2. Создаем дескриптор и заполняем его текущими данными из БД.
            // Это важно, чтобы не потерять те данные, которые мы не редактируем (например, Permissions)
            var descriptor = new OpenIddictApplicationDescriptor();
            await _manager.PopulateAsync(descriptor, app, cancellationToken);

            // 3. Применяем изменения из модели в дескриптор
            descriptor.DisplayName = model.DisplayName;
            descriptor.ClientType = model.Type;

            // Обновляем Redirect URIs
            descriptor.RedirectUris.Clear();
            if (!string.IsNullOrEmpty(model.RedirectUri))
            {
                descriptor.RedirectUris.Add(new Uri(model.RedirectUri));
            }

            // Обновляем Secret ТОЛЬКО если пользователь ввел новый и тип Confidential
            if (!string.IsNullOrEmpty(model.ClientSecret) && model.Type == ClientTypes.Confidential)
            {
                descriptor.ClientSecret = model.ClientSecret;
            }
            
            // Если переключили на Public, удаляем секрет (безопасность)
            if (model.Type == ClientTypes.Public)
            {
                descriptor.ClientSecret = null;
            }

            try
            {
                // 4. Сохраняем изменения через менеджер
                await _manager.UpdateAsync(app, descriptor, cancellationToken);
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                ModelState.AddModelError(string.Empty, $"Ошибка обновления: {ex.Message}");
                return View(model);
            }
        }
		
    }
}