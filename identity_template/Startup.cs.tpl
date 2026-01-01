using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using MyApp.Identity.Data;
using OpenIddict.Abstractions;

namespace MyApp.Identity
{
    public class Startup
    {
     public IConfiguration AppConfiguration { get; }
//TODO: Update to use new configuration pattern

        public Startup(IConfiguration configuration) =>
            AppConfiguration = configuration;
        #region ConfigureServices
        public void ConfigureServices(IServiceCollection services)
        {
            var connectionString = AppConfiguration.GetValue<string>("DbConnection");

            services.AddDbContext<AuthDbContext>(options =>
            {
                options.UseSqlite(connectionString);
                options.UseOpenIddict();
            });
            
            services.AddIdentity<ApplicationUser, ApplicationRole>(options =>
            {
                // optional: configure password/lockout/etc here for development
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequireUppercase = false;
            })
            .AddEntityFrameworkStores<AuthDbContext>()
            .AddDefaultTokenProviders();

            services.AddControllersWithViews();
            services.AddAuthentication();
            services.AddAuthorization(options =>
            {
                options.AddPolicy("Administrator", policy =>
                    policy.RequireRole("Administrator"));
            });
            services.AddRazorPages();
            //--------------------------------------------
            services.AddOpenIddict()


            .AddCore(options =>
            {
                // Configure OpenIddict to use the Entity Framework Core stores and models.
                // Note: call ReplaceDefaultEntities() to replace the default entities.
                options.UseEntityFrameworkCore()
                    .UseDbContext<AuthDbContext>();
            })
            .AddClient(
            options =>
            {
                // Note: this sample uses the code flow, but you can enable the other flows if necessary.
                options.AllowAuthorizationCodeFlow();

                // Register the signing and encryption credentials used to protect
                // sensitive data like the state tokens produced by OpenIddict.
                options.AddDevelopmentEncryptionCertificate()
                       .AddDevelopmentSigningCertificate();

                // Register the ASP.NET Core host and configure the ASP.NET Core-specific options.
                options.UseAspNetCore()
                       .EnableStatusCodePagesIntegration()
                       .EnableRedirectionEndpointPassthrough();

                // Register the System.Net.Http integration and use the identity of the current
                // assembly as a more specific user agent, which can be useful when dealing with
                // providers that use the user agent as a way to throttle requests (e.g Reddit).
                options.UseSystemNetHttp()
                       .SetProductInformation(typeof(Startup).Assembly);

                // Register the Web providers integrations.
                //
                // Note: to mitigate mix-up attacks, it's recommended to use a unique redirection endpoint
                // URI per provider, unless all the registered providers support returning a special "iss"
                // parameter containing their URL as part of authorization responses. For more information,
                // see https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics#section-4.4.
                options.UseWebProviders()
                       .AddGitHub(options =>
                       {
                           options.SetClientId("c4ade52327b01ddacff3")
                                  .SetClientSecret("da6bed851b75e317bf6b2cb67013679d9467c122")
                                  .SetRedirectUri("callback/login/github");
                       });
            })
            .AddServer(options =>
            {
                 options
        .AllowAuthorizationCodeFlow()
        .AllowRefreshTokenFlow();

        options.RegisterScopes(
            OpenIddictConstants.Scopes.Email, 
        OpenIddictConstants.Scopes.Profile, 
        OpenIddictConstants.Scopes.OpenId);

    options
        .SetAuthorizationEndpointUris("connect/authorize")
                       .SetEndSessionEndpointUris("connect/logout")
                       .SetTokenEndpointUris("connect/token")
                       .SetUserInfoEndpointUris("connect/userinfo");


services.AddTransient<Microsoft.AspNetCore.Identity.UI.Services.IEmailSender, EmailSender>();
                // Register the signing and encryption credentials.
                options.AddDevelopmentEncryptionCertificate()
                    .AddDevelopmentSigningCertificate();

                // Register the ASP.NET Core host and configure the ASP.NET Core options.
                options.UseAspNetCore()
                    .EnableAuthorizationEndpointPassthrough()
                       .EnableEndSessionEndpointPassthrough()
                       .EnableStatusCodePagesIntegration()
                       .EnableTokenEndpointPassthrough();
            }).AddValidation(options =>
            {
                // Import the configuration from the local OpenIddict server instance.
                options.UseLocalServer();

                // Register the ASP.NET Core host.
                options.UseAspNetCore();
            });
            //--------------------------------------------
services.AddControllersWithViews();
        services.AddRazorPages();

        // Register the worker responsible for seeding the database.
        // Note: in a real world application, this step should be part of a setup script.
        services.AddHostedService<Worker>();
        }
        #endregion



        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseStaticFiles(new StaticFileOptions()
            {
                FileProvider = new PhysicalFileProvider(
                    Path.Combine(Directory.GetCurrentDirectory(), "Styles")),
                RequestPath = "/styles"
            });
            app.UseRouting();

            app.UseAuthentication();
            app.UseAuthorization();

            
			
			app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
    
                // MVC маршруты (conventional routing)
                endpoints.MapControllerRoute(
                    name: "default",
                    pattern: "{controller=Home}/{action=Index}/{id?}");
                
                // Razor Pages (если используются)
                endpoints.MapRazorPages();
            });

            // Seed the admin user
           using (var scope = app.ApplicationServices.CreateScope())
            {
                var userManager = scope.ServiceProvider.GetRequiredService<
                UserManager<ApplicationUser>>();
                                var roleManager = scope.ServiceProvider.GetRequiredService<
                RoleManager<ApplicationRole>>();
                AdminSeeder.CreateAdminUser(userManager,roleManager).GetAwaiter().GetResult();
            } 
        }
       
    }

public class EmailSender : Microsoft.AspNetCore.Identity.UI.Services.IEmailSender
{
    private readonly ILogger<EmailSender> _log;
    public EmailSender(ILogger<EmailSender> log) => _log = log;

    public Task SendEmailAsync(string email, string subject, string htmlMessage)
    {
        _log.LogInformation("SendEmailAsync to {Email}: {Subject}", email, subject);
        // тут можно вызвать SMTP/SendGrid и т.д.
        return Task.CompletedTask;
    }
}
}