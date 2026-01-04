using Microsoft.AspNetCore.Identity; // Важно: добавить этот using
using OpenIddict.Abstractions;
using {{Namespace}}.Data;
using OpenIddict.Abstractions;

namespace {{Namespace}};

public class Worker : IHostedService
{
    private readonly IServiceProvider _serviceProvider;

    public Worker(IServiceProvider serviceProvider)
        => _serviceProvider = serviceProvider;

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();

        // 1. Инициализация Базы Данных
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        await context.Database.EnsureCreatedAsync(cancellationToken);

        // 2. Создание Администратора (НОВОЕ)
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<IdentityUser>>();
        
        const string adminEmail = "admin@admin.com";
        const string adminPassword = "Password123!"; // Пароль должен быть сложным (Identity по умолчанию требует: Цифру, Букву, Заглавную, Спецсимвол)

        var adminUser = await userManager.FindByEmailAsync(adminEmail);
        
        if (adminUser is null)
        {
            var user = new IdentityUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true // Сразу подтверждаем email, чтобы можно было войти
            };

            var result = await userManager.CreateAsync(user, adminPassword);
            
            if (!result.Succeeded)
            {
                // Логирование ошибки, если не удалось создать (например, пароль слишком простой)
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                throw new Exception($"Не удалось создать админа: {errors}");
            }
        }

        // 3. Создание Клиентского приложения (OpenIddict)
        var manager = scope.ServiceProvider.GetRequiredService<IOpenIddictApplicationManager>();

        if (await manager.FindByClientIdAsync("postman", cancellationToken) is null)
        {
            await manager.CreateAsync(new OpenIddictApplicationDescriptor
            {
                ClientId = "postman",
                ClientSecret = "postman-secret",
                DisplayName = "Postman Client",
                Permissions =
                {
                    OpenIddictConstants.Permissions.Endpoints.Token,
                    OpenIddictConstants.Permissions.GrantTypes.ClientCredentials,
                    OpenIddictConstants.Permissions.ResponseTypes.Code
                }
            }, cancellationToken);
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}