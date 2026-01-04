using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using {{Namespace}};
using {{Namespace}}.Data;

var builder = WebApplication.CreateBuilder(args);

// 1111. Настройка БД (SQLite)
// Примечание: ConnectionString будет добавлен в appsettings.json позже или автоматически
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=auth.db";

builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlite(connectionString);
    
    // Регистрируем сущности OpenIddict
    options.UseOpenIddict();
});

// 2. Настройка Identity (Cookie Auth для Админки)
builder.Services.AddDefaultIdentity<IdentityUser>(options => 
{
    options.SignIn.RequireConfirmedAccount = false; // Для упрощения
})
.AddEntityFrameworkStores<ApplicationDbContext>();

// 3. Настройка OpenIddict
builder.Services.AddOpenIddict()
    // Регистрируем ядро OpenIddict
    .AddCore(options =>
    {
        options.UseEntityFrameworkCore()
               .UseDbContext<ApplicationDbContext>();
    })
    // Регистрируем Сервер (Server)
    .AddServer(options =>
    {
        // Указываем эндпоинты
        options.SetTokenEndpointUris("/connect/token")
               .SetAuthorizationEndpointUris("/connect/authorize")
               .SetUserInfoEndpointUris("/connect/userinfo");

        // Разрешаем потоки (Flows)
        options.AllowAuthorizationCodeFlow()
               .AllowClientCredentialsFlow()
               .AllowRefreshTokenFlow();

        // Для разработки используем временные ключи шифрования
        // В продакшене нужен настоящий сертификат!
        options.AddDevelopmentEncryptionCertificate()
               .AddDevelopmentSigningCertificate();

        // Интеграция с ASP.NET Core
        options.UseAspNetCore()
               .EnableTokenEndpointPassthrough()
               .EnableAuthorizationEndpointPassthrough()
               .EnableUserInfoEndpointPassthrough();
    })
    // Регистрируем Валидацию (опционально, если сервер сам себя проверяет)
    .AddValidation(options =>
    {
        options.UseLocalServer();
        options.UseAspNetCore();
    });

builder.Services.AddControllersWithViews();
builder.Services.AddRazorPages(); // Необходимо для Identity UI

// --- Ворк для инициализации БД и создания тестового приложения OpenIddict ---
builder.Services.AddHostedService<Worker>();

var app = builder.Build();

// Pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication(); // Важно: аутентификация
app.UseAuthorization();  // Важно: авторизация

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapRazorPages(); // Маппинг страниц Identity

app.Run();