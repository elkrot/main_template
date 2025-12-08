#Identity 
if (Test-Path $IdentityRootName) { Remove-Item $IdentityRootName -Recurse -Force }
New-Item -ItemType Directory -Name $IdentityRootName
cd $IdentityRootName
$identitySolutionProjName =$identitySolutionName+'.csproj'
$identitySolutionFulPath ='.\'+$identitySolutionName
$identitySolutionFulName=$identitySolutionFulPath+'.sln'
$identitySolutionProjPath = Join-Path $identitySolutionFulPath  $identitySolutionProjName

dotnet new sln --name $identitySolutionName
dotnet new web --framework $framework --name $identitySolutionName --output $identitySolutionName
dotnet sln $identitySolutionFulName add $identitySolutionProjPath

dotnet dev-certs https --trust

#openidict

dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.Server.AspNetCore --version "7.*"
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.AspNetCore --version "7.*"
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.Core --version "7.*"
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.EntityFrameworkCore --version "7.*"
dotnet add $identitySolutionProjPath package --framework $framework OpenIddict.Validation.AspNetCore --version "7.*"

dotnet add $identitySolutionProjPath package Microsoft.AspNetCore.Identity.EntityFrameworkCore --version $pversion
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore --version $pversion
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore.Design --version $pversion
dotnet add $identitySolutionProjPath package Microsoft.EntityFrameworkCore.Sqlite --version $pversion



dotnet add $identitySolutionProjPath package --framework $framework Microsoft.VisualStudio.Web.CodeGeneration.Design --version $pversion
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore.Design --version $pversion

dotnet add $identitySolutionProjPath package --framework $framework Microsoft.AspNetCore.Identity.UI --version $pversion
#dotnet add $identitySolutionProjPath package Microsoft.EntityFrameworkCore.SqlServer
dotnet add $identitySolutionProjPath package --framework $framework Microsoft.EntityFrameworkCore.Tools --version $pversion




New-Item -ItemType Directory -Path "$($identitySolutionName)\Controllers"	 -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Data"	 -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Models"	 -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Views\Authorization"	 -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Styles" -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Views\Admin"	 -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Views\Applications"	 -Force
New-Item -ItemType Directory -Path "$($identitySolutionName)\Services"	 -Force


@" 
{
  "DbConnection": "Data Source=$($VendorName).Auth.db",
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*"
}

"@ | Set-Content -Path "$($identitySolutionName)\appsettings.json"
@" 
using System.Collections.Generic;
using static OpenIddict.Abstractions.OpenIddictConstants;


namespace $($identitySolutionName)
{
    public static class Configuration
    {
       /* public static IEnumerable<ApiScope> ApiScopes =>
            new List<ApiScope>
            {
                new ApiScope("NotesWebAPI", "Web API")
            };

        public static IEnumerable<IdentityResource> IdentityResources =>
            new List<IdentityResource>
            {
                new IdentityResources.OpenId(),
                new IdentityResources.Profile()
            };

        public static IEnumerable<ApiResource> ApiResources =>
            new List<ApiResource>
            {
                new ApiResource("NotesWebAPI", "Web API", new []
                    { JwtClaimTypes.Name})
                {
                    Scopes = {"NotesWebAPI"}
                }
            };

        public static IEnumerable<Client> Clients =>
            new List<Client>
            {
                new Client
                {
                    ClientId = "notes-web-app",
                    ClientName = "Notes Web",
                    AllowedGrantTypes = GrantTypes.Code,
                    RequireClientSecret = false,
                    RequirePkce = true,
                    RedirectUris =
                    {
                        "http://localhost:3000/signin-oidc"
                    },
                    AllowedCorsOrigins =
                    {
                        "http://localhost:3000"
                    },
                    PostLogoutRedirectUris =
                    {
                        "http://localhost:3000/signout-oidc"
                    },
                    AllowedScopes =
                    {
                        IdentityServerConstants.StandardScopes.OpenId,
                        IdentityServerConstants.StandardScopes.Profile,
                        "NotesWebAPI"
                    },
                    AllowAccessTokensViaBrowser = true
                }
            };*/
    }
}

"@ | Set-Content -Path "$($identitySolutionName)\Configuration.cs"
@" 
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Mvc;
using OpenIddict.Abstractions;
using OpenIddict.Server.AspNetCore;
using System.Security.Claims;

using Microsoft.IdentityModel.Tokens;
using static OpenIddict.Abstractions.OpenIddictConstants;
using Microsoft.AspNetCore.Identity;
using MyApp.Identity.Data;
using MyApp.Identity.Models;

namespace MyApp.Identity.Controllers
{
    public class AuthorizationController : Controller
    {
        private readonly IOpenIddictApplicationManager _applicationManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;

  
        public AuthorizationController(
                   IOpenIddictApplicationManager applicationManager,
                   UserManager<ApplicationUser> userManager,
                   SignInManager<ApplicationUser> signInManager)
        {
            _applicationManager = applicationManager;
            _userManager = userManager;
            _signInManager = signInManager;
        }

        [HttpPost("~/connect/token"), Produces("application/json")]
        public async Task<IActionResult> Exchange()
        {
            var request = HttpContext.GetOpenIddictServerRequest();
            if (request.IsClientCredentialsGrantType())
            {
                // Note: the client credentials are automatically validated by OpenIddict:
                // if client_id or client_secret are invalid, this action won't be invoked.

                var application = await _applicationManager.FindByClientIdAsync(request.ClientId) ??
                    throw new InvalidOperationException("The application cannot be found.");

                // Create a new ClaimsIdentity containing the claims that
                // will be used to create an id_token, a token or a code.
                var identity = new ClaimsIdentity(TokenValidationParameters.DefaultAuthenticationType, Claims.Name, Claims.Role);

                // Use the client_id as the subject identifier.
                identity.SetClaim(Claims.Subject, await _applicationManager.GetClientIdAsync(application));
                identity.SetClaim(Claims.Name, await _applicationManager.GetDisplayNameAsync(application));

                identity.SetDestinations(static claim => claim.Type switch
                {
                    // Allow the "name" claim to be stored in both the access and identity tokens
                    // when the "profile" scope was granted (by calling principal.SetScopes(...)).
                    Claims.Name when claim.Subject.HasScope(Scopes.Profile)
                        => [Destinations.AccessToken, Destinations.IdentityToken],

                    // Otherwise, only store the claim in the access tokens.
                    _ => [Destinations.AccessToken]
                });

                return SignIn(new ClaimsPrincipal(identity), OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);
            }

            throw new NotImplementedException("The specified grant is not implemented.");
        }


        [HttpPost("~/connect/authorize"), Produces("application/json")]
        public async Task<IActionResult> Authorize([FromForm] string username, [FromForm] string password)
        {
            // Try by user name, then by email
            var user = await _userManager.FindByNameAsync(username) ?? await _userManager.FindByEmailAsync(username);
            if (user == null)
                return Unauthorized();

            var result = await _signInManager.CheckPasswordSignInAsync(user, password, lockoutOnFailure: false);
            if (!result.Succeeded)
                return Unauthorized();

            // Create principal and set claim destinations for OpenIddict
            var principal = await _signInManager.CreateUserPrincipalAsync(user);
            if (principal.Identity is ClaimsIdentity identity)
            {
                identity.SetDestinations(claim =>
                    claim.Type switch
                    {
                        Claims.Name => new[] { Destinations.AccessToken, Destinations.IdentityToken },
                        _ => new[] { Destinations.AccessToken }
                    });
            }

            // Issue token using OpenIddict's server authentication scheme
            return SignIn(principal, OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);
        }


[HttpGet("~/account/register")]
        public IActionResult Register(string returnUrl="~/")
        {
            var viewModel = new RegisterViewModel
            {
                ReturnUrl = returnUrl
            };
            return View(viewModel);
        }

        [HttpPost("~/account/register")]
        public async Task<IActionResult> Register(RegisterViewModel viewModel)
        {
            if (!ModelState.IsValid)
            {
                return View(viewModel);
            }

            var user = new ApplicationUser
            {
                UserName = viewModel.Username
            };

            var result = await _userManager.CreateAsync(user, viewModel.Password);
            if (result.Succeeded)
            {
                await _signInManager.SignInAsync(user, false);
                return Redirect(viewModel.ReturnUrl);
            }
            ModelState.AddModelError(string.Empty, "Error occurred");
            return View(viewModel);
        }

        [HttpGet("~/account/logout")]
        public async Task<IActionResult> Logout(string logoutId)
        {
            await _signInManager.SignOutAsync();
            //var logoutRequest = await _interactionService.GetLogoutContextAsync(logoutId);

            var logoutRequest = await Task.FromResult(new { PostLogoutRedirectUri = "/" }); 
            return Redirect(logoutRequest.PostLogoutRedirectUri);
        }

        [HttpGet("~/account/login")]
        public IActionResult Login(string returnUrl= "/")
        {
            var viewModel = new LoginViewModel
            {
                ReturnUrl = returnUrl
            };
            return View(viewModel);
        }

        [HttpPost("~/account/login")]
        public async Task<IActionResult> Login(LoginViewModel viewModel)
        {
            if (!ModelState.IsValid)
            {
                return View(viewModel);
            }  
            var user = await _userManager.FindByNameAsync(viewModel.Username) ??
            await _userManager.FindByEmailAsync(viewModel.Username);
            if (user == null)
                return Unauthorized();

            var result = await _signInManager.CheckPasswordSignInAsync(user, viewModel.Password, lockoutOnFailure: false);
            if (!result.Succeeded)
                return Unauthorized();

            // Create principal and set claim destinations for OpenIddict
            var principal = await _signInManager.CreateUserPrincipalAsync(user);
            if (principal.Identity is ClaimsIdentity identity)
            {
                identity.SetDestinations(claim =>
                    claim.Type switch
                    {
                        Claims.Name => new[] { Destinations.AccessToken, Destinations.IdentityToken },
                        _ => new[] { Destinations.AccessToken }
                    });
            }
            // Issue token using OpenIddict's server authentication scheme
            return SignIn(principal, OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);






           
        }


    }
}



"@ | Set-Content -Path "$($identitySolutionName)\Controllers\AuthorizationController.cs"

@"
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace $($identitySolutionName).Controllers
{
// Controllers/AdminController.cs
[Authorize(Roles = "Administrator")]
[Route("admin")]
public class AdminController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}
}
"@ | Set-Content -Path "$($identitySolutionName)\Controllers\AdminController.cs"


@"
using Microsoft.AspNetCore.Mvc;
using OpenIddict.Abstractions;
using Microsoft.AspNetCore.Authorization;
using $($identitySolutionName).Models;

namespace $($identitySolutionName).Controllers
{
//Controllers/ApplicationsController.cs
[Authorize(Roles = "Administrator")]
[Route("admin/applications")]
public class ApplicationsController : Controller
{
    private readonly IOpenIddictApplicationManager _applicationManager;

    public ApplicationsController(IOpenIddictApplicationManager applicationManager)
        => _applicationManager = applicationManager;

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var applications = new List<object>();
        await foreach (var application in _applicationManager.ListAsync())
        {
            var descriptor = new OpenIddictApplicationDescriptor();
            await _applicationManager.PopulateAsync(descriptor, application);
            applications.Add(descriptor);
        }

        return View(applications);
    }

    [HttpGet("create")]
    public IActionResult Create() => View(new ApplicationViewModel());

    [HttpPost("create")]
    public async Task<IActionResult> Create(ApplicationViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        var descriptor = new OpenIddictApplicationDescriptor
        {
            ClientId = model.ClientId!,
            ClientSecret = model.ClientSecret,
            DisplayName = model.DisplayName,
        };

        foreach (var uri in model.RedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.RedirectUris.Add(new Uri(uri!));

        foreach (var uri in model.PostLogoutRedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.PostLogoutRedirectUris.Add(new Uri(uri!));

        foreach (var permission in model.Permissions.Where(p => !string.IsNullOrEmpty(p)))
            descriptor.Permissions.Add(permission!);

        foreach (var requirement in model.Requirements.Where(r => !string.IsNullOrEmpty(r)))
            descriptor.Requirements.Add(requirement!);

        await _applicationManager.CreateAsync(descriptor);

        return RedirectToAction(nameof(Index));
    }

    [HttpGet("edit/{id}")]
    public async Task<IActionResult> Edit(string id)
    {
        var application = await _applicationManager.FindByIdAsync(id);
        if (application == null)
            return NotFound();

        var descriptor = new OpenIddictApplicationDescriptor();
        await _applicationManager.PopulateAsync(descriptor, application);

        var model = new ApplicationViewModel
        {
            ClientId = descriptor.ClientId,
            DisplayName = descriptor.DisplayName,
            RedirectUris = descriptor.RedirectUris.Select(u => u.ToString()).ToList(),
            PostLogoutRedirectUris = descriptor.PostLogoutRedirectUris.Select(u => u.ToString()).ToList(),
            Permissions = descriptor.Permissions.ToList(),
            Requirements = descriptor.Requirements.ToList()
        };

        return View(model);
    }

    [HttpPost("edit/{id}")]
    public async Task<IActionResult> Edit(string id, ApplicationViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        var application = await _applicationManager.FindByIdAsync(id);
        if (application == null)
            return NotFound();

        var descriptor = new OpenIddictApplicationDescriptor();
        await _applicationManager.PopulateAsync(descriptor, application);

        descriptor.ClientId = model.ClientId!;
        descriptor.DisplayName = model.DisplayName;
        
        if (!string.IsNullOrEmpty(model.ClientSecret))
            descriptor.ClientSecret = model.ClientSecret;

        descriptor.RedirectUris.Clear();
        foreach (var uri in model.RedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.RedirectUris.Add(new Uri(uri!));

        descriptor.PostLogoutRedirectUris.Clear();
        foreach (var uri in model.PostLogoutRedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.PostLogoutRedirectUris.Add(new Uri(uri!));

        descriptor.Permissions.Clear();
        foreach (var permission in model.Permissions.Where(p => !string.IsNullOrEmpty(p)))
            descriptor.Permissions.Add(permission!);

        descriptor.Requirements.Clear();
        foreach (var requirement in model.Requirements.Where(r => !string.IsNullOrEmpty(r)))
            descriptor.Requirements.Add(requirement!);

        await _applicationManager.UpdateAsync(application, descriptor);

        return RedirectToAction(nameof(Index));
    }

    [HttpPost("delete/{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var application = await _applicationManager.FindByIdAsync(id);
        if (application != null)
        {
            await _applicationManager.DeleteAsync(application);
        }

        return RedirectToAction(nameof(Index));
    }
}
}



"@ | Set-Content -Path "$($identitySolutionName)\Controllers\ApplicationsController.cs"



@" 
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using $($identitySolutionName).Models;

namespace $($identitySolutionName).Data
{
    public class AppUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
    {
        public void Configure(EntityTypeBuilder<ApplicationUser> builder)
        {
            builder.HasKey(x => x.Id);
        }
    }
}

"@ | Set-Content -Path "$($identitySolutionName)\Data\AppUserConfiguration.cs"

@" 
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace MyApp.Identity.Data
{
    // Используем стандартный IdentityUser и IdentityRole
    public class ApplicationUser : IdentityUser { }
    public class ApplicationRole : IdentityRole { }

    // Контекст наследуется от IdentityDbContext для Identity
    public class AuthDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
    {
        public AuthDbContext(DbContextOptions<AuthDbContext> options)
            : base(options) { }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Настраиваем EF Core для OpenIddict, который использует свои таблицы.
            // Это должно быть вызвано после base.OnModelCreating(builder);
            //TODO: проверить необходимость этой строки
            //builder.ConfigureOpenIddict();
        }
    }
}



"@ | Set-Content -Path "$($identitySolutionName)\Data\AuthDbContext.cs"
@" 
namespace $($identitySolutionName).Data
{
    public class DbInitializer
    {
        public static void Initialize(AuthDbContext context)
        {
            context.Database.EnsureCreated();
        }
    }
}

"@ | Set-Content -Path "$($identitySolutionName)\Data\DbInitializer.cs"


@" 
using System.ComponentModel.DataAnnotations;

namespace $($identitySolutionName).Models
{
    public class LoginViewModel
    {
        [Required]
        public string Username { get; set; }
        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; }
        public string ReturnUrl { get; set; }
    }
}

"@ | Set-Content -Path "$($identitySolutionName)\Models\LoginViewModel.cs"


@" 
using System.ComponentModel.DataAnnotations;

namespace $($identitySolutionName).Models
{
    public class ApplicationViewModel
{
	[Required]
    public string? ClientId { get; set; }
    public string? DisplayName { get; set; }
    [Required]
    [DataType(DataType.Password)]
    public string? ClientSecret { get; set; }
    public List<string> RedirectUris { get; set; } = new();
    public List<string> PostLogoutRedirectUris { get; set; } = new();
    public List<string> Permissions { get; set; } = new();
    public List<string> Requirements { get; set; } = new();
}

}

"@ | Set-Content -Path "$($identitySolutionName)\Models\ApplicationViewModel.cs"


@" 
using System.ComponentModel.DataAnnotations;

namespace $($identitySolutionName).Models
{
   public class ScopeViewModel
{
    public string? Name { get; set; }
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public List<string> Resources { get; set; } = new();
}
}

"@ | Set-Content -Path "$($identitySolutionName)\Models\ScopeViewModel.cs"


@" 
using System.ComponentModel.DataAnnotations;

namespace $($identitySolutionName).Models
{
    public class RegisterViewModel
    {
        [Required]
        public string Username { get; set; }
        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; }
        [Required]
        [DataType(DataType.Password)]
        [Compare("Password")]
        public string ConfirmPassword { get; set; }
        public string ReturnUrl { get; set; }
    }
}

"@ | Set-Content -Path "$($identitySolutionName)\Models\RegisterViewModel.cs"

@" 
using $($identitySolutionName).Data;

namespace $($identitySolutionName)
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var host = CreateHostBuilder(args).Build();
            using(var scope = host.Services.CreateScope())
            {
                var serviceProvider = scope.ServiceProvider;
                try
                {
                    var context = serviceProvider.GetRequiredService<AuthDbContext>();
                    DbInitializer.Initialize(context);
                }
                catch (Exception exception)
                {
                    var logger = serviceProvider.GetRequiredService<ILogger<Program>>();
                    logger.LogError(exception, "An error occurred while app initialization");
                }
            }
            host.Run();	
			
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}


"@ | Set-Content -Path "$($identitySolutionName)\Program.cs"

@" 
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
"@ | Set-Content -Path "$($identitySolutionName)\Startup.cs"


@"
using $($identitySolutionName).Data;
using OpenIddict.Abstractions;
using static OpenIddict.Abstractions.OpenIddictConstants;

namespace $($identitySolutionName);

public class Worker : IHostedService
{
    private readonly IServiceProvider _serviceProvider;

    public Worker(IServiceProvider serviceProvider)
        => _serviceProvider = serviceProvider;

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using var scope = _serviceProvider.CreateAsyncScope();

        var context = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
        await context.Database.EnsureCreatedAsync();

        var manager = scope.ServiceProvider.GetRequiredService<IOpenIddictApplicationManager>();

        if (await manager.FindByClientIdAsync("balosar-blazor-client") is null)
        {
            await manager.CreateAsync(new OpenIddictApplicationDescriptor
            {
                ClientId = "balosar-blazor-client",
                ConsentType = ConsentTypes.Explicit,
                DisplayName = "Blazor client application",
                ClientType = ClientTypes.Public,
                PostLogoutRedirectUris =
                {
                    new Uri("https://localhost:44310/authentication/logout-callback")
                },
                RedirectUris =
                {
                    new Uri("https://localhost:44310/authentication/login-callback")
                },
                Permissions =
                {
                    Permissions.Endpoints.Authorization,
                    Permissions.Endpoints.EndSession,
                    Permissions.Endpoints.Token,
                    Permissions.GrantTypes.AuthorizationCode,
                    Permissions.GrantTypes.RefreshToken,
                    Permissions.ResponseTypes.Code,
                    Permissions.Scopes.Email,
                    Permissions.Scopes.Profile,
                    Permissions.Scopes.Roles
                },
                Requirements =
                {
                    Requirements.Features.ProofKeyForCodeExchange
                }
            });
        }

    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}

"@ | Set-Content -Path "$($identitySolutionName)\Worker.cs"

@" 
@using $($identitySolutionName).Models
@addTagHelper "*, Microsoft.AspNetCore.Mvc.TagHelpers"
"@ | Set-Content -Path "$($identitySolutionName)\Views\_ViewImports.cshtml"

@" 
@model LoginViewModel
<head>
    <link href=@Url.Content("~/styles/app.css") rel="stylesheet" type="text/css"/>
</head>
<form asp-controller="Authorization" asp-action="Authorize" method="post">
    <input type="hidden" asp-for="ReturnUrl" />
    <div class="header">Login</div>
    <div class="block">
        <label>Username</label>
        <input asp-for="Username" class="input"/>
        <span asp-validation-for="Username"></span>
    </div>
    <div class="block">
        <label>Password</label>
        <input asp-for="Password" class="input"/>
        <span asp-validation-for="Password"></span>
    </div>
    <div class="block">
        <button type="submit" class="button">Sign In</button>
    </div>
    <a asp-controller="Authorization" asp-action="Register"
       asp-route-returnUrl="@Model.ReturnUrl" class="switch-button">Register</a>
</form>
"@ | Set-Content -Path "$($identitySolutionName)\Views\Authorization\Login.cshtml"
@" 
@model RegisterViewModel
<head>
    <link href=@Url.Content("~/styles/app.css") rel="stylesheet" type="text/css"/>
</head>
<form asp-controller="Authorization" asp-action="Register" method="post">
    <input type="hidden" asp-for="ReturnUrl" />
    <div class="header">Sign Up</div>
    <div class="block">
        <label>Username</label>
        <input asp-for="Username" class="input" />
        <span asp-validation-for="Username"></span>
    </div>
    <div class="block">
        <label>Password</label>
        <input asp-for="Password" class="input" />
        <span asp-validation-for="Password"></span>
    </div>
    <div class="block">
        <label>Confirm password</label>
        <input asp-for="ConfirmPassword" class="input" />
        <span asp-validation-for="ConfirmPassword"></span>
    </div>
    <div class="block">
        <button type="submit" class="button">Sign up</button>
    </div>
    <a asp-controller="Authorization" asp-action="Login" asp-route-returnUrl="@Model.ReturnUrl"
       class="switch-button">Login</a>
</form>
"@ | Set-Content -Path "$($identitySolutionName)\Views\Authorization\Register.cshtml"



@" 
<!-- Views/Admin/Index.cshtml -->
@{
    ViewData["Title"] = "OpenIddict Admin";
}

<div class="container mt-4">
    <h2>OpenIddict Administration</h2>
    <div class="row">
        <div class="col-md-4">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Applications</h5>
                    <p class="card-text">Manage OAuth2/OpenID Connect applications</p>
                    <a href="@Url.Action("Index", "Applications")" class="btn btn-primary">Manage</a>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Scopes</h5>
                    <p class="card-text">Manage API scopes and resources</p>
                    <a href="#" class="btn btn-primary">Manage</a>
                </div>
            </div>
        </div>
    </div>
</div>
"@ | Set-Content -Path "$($identitySolutionName)\Views\Admin\Index.cshtml"



@" 
<!-- Views/Applications/Index.cshtml -->
@model List<object>
@{
    ViewData["Title"] = "Applications";
}

<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center">
        <h2>OAuth2 Applications</h2>
        <a href="@Url.Action("Create")" class="btn btn-success">Create New</a>
    </div>

    <table class="table table-striped mt-3">
        <thead>
            <tr>
                <th>Client ID</th>
                <th>Display Name</th>
                <th>Type</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach (dynamic app in Model)
            {
                <tr>
                    <td>@app.ClientId</td>
                    <td>@app.DisplayName</td>
                    <td>@app.Type</td>
                    <td>
                        <a href="@Url.Action("Edit", new { id = app.ApplicationId })" class="btn btn-sm btn-primary">Edit</a>
                        <form method="post" action="@Url.Action("Delete", new { id = app.ApplicationId })" class="d-inline">
                            <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Are you sure?')">Delete</button>
                        </form>
                    </td>
                </tr>
            }
        </tbody>
    </table>
</div>
"@ | Set-Content -Path "$($identitySolutionName)\Views\Applications\Index.cshtml"


@" 
<!-- Views/Applications/Create.cshtml -->
@model ApplicationViewModel
@{
    ViewData["Title"] = "Create Application";
}

<div class="container mt-4">
    <h2>Create Application</h2>

    <form method="post">
        <div class="form-group">
            <label asp-for="ClientId"></label>
            <input asp-for="ClientId" class="form-control" />
            <span asp-validation-for="ClientId" class="text-danger"></span>
        </div>

        <div class="form-group">
            <label asp-for="DisplayName"></label>
            <input asp-for="DisplayName" class="form-control" />
            <span asp-validation-for="DisplayName" class="text-danger"></span>
        </div>

        <div class="form-group">
            <label asp-for="ClientSecret"></label>
            <input asp-for="ClientSecret" class="form-control" />
            <span asp-validation-for="ClientSecret" class="text-danger"></span>
        </div>

        <div class="form-group">
            <label>Redirect URIs (one per line)</label>
            <textarea name="RedirectUris" class="form-control" rows="3">@string.Join("\n", Model.RedirectUris)</textarea>
        </div>

        <div class="form-group">
            <label>Post Logout Redirect URIs (one per line)</label>
            <textarea name="PostLogoutRedirectUris" class="form-control" rows="3">@string.Join("\n", Model.PostLogoutRedirectUris)</textarea>
        </div>

        <div class="form-group">
            <label>Permissions (one per line)</label>
            <textarea name="Permissions" class="form-control" rows="3">@string.Join("\n", Model.Permissions)</textarea>
        </div>

        <button type="submit" class="btn btn-primary">Create</button>
        <a href="@Url.Action("Index")" class="btn btn-secondary">Cancel</a>
    </form>
</div>
"@ | Set-Content -Path "$($identitySolutionName)\Views\Applications\Create.cshtml"

@"
using Microsoft.AspNetCore.Identity;
using $($identitySolutionName).Data;

namespace $($identitySolutionName)
{
// Services/AdminSeeder.cs
public static class AdminSeeder
{
    public static async Task CreateAdminUser(UserManager<ApplicationUser> userManager,
     RoleManager<ApplicationRole> roleManager)
    {
            if (!await roleManager.RoleExistsAsync("Administrator"))
            {
                await roleManager.CreateAsync(new ApplicationRole(){Name = "Administrator"});
            }

        var adminUser = await userManager.FindByNameAsync("admin");
        if (adminUser == null)
        {
            adminUser = new ApplicationUser { UserName = "admin", Email = "admin@example.com" };
            await userManager.CreateAsync(adminUser, "Admin123!");
            await userManager.AddToRoleAsync(adminUser, "Administrator");
        }
    }
}
}
"@ | Set-Content -Path "$($identitySolutionName)\Services\AdminSeeder.cs"

@" 
.input {
    font-size: 16px;
    font-family: Arial;
    background-color: #fff;
    width: 100%;
}

.header {
    font-family: Arial;
    color: #332600;
    font-size: 30px;
    text-align: center;
}

.button {
    font-size: 16px;
    background-color: #a191bd;
    border-radius: 4px;
    color: #332600;
    font-family: Arial;
    width: 100%;
}

.block {
    margin-top: 10px;
}

.switch-button {
    margin-top: 8px;
    font-size: 8px;
    border-radius: 4px;
    color: #332600;
    font-family: Arial;
    display: inline-block;
    text-align: center;
    width: 100%;
}
"@ | Set-Content -Path "$($identitySolutionName)\Styles\app.css"



#dotnet run --launch-profile "https"
#dotnet add package OrchardCore.Application.OpenId
#services.AddOrchardCore().AddOpenId().AddMvc();


#DotnetEnv ,вставлять куски файлов в основной файл
dotnet tool uninstall --global dotnet-ef
dotnet tool uninstall -g dotnet-aspnet-codegenerator

dotnet tool install -g dotnet-aspnet-codegenerator --version $pversion
dotnet tool install --global dotnet-ef --version $pversion

cd $identitySolutionName
dotnet aspnet-codegenerator identity -dc $identitySolutionName.Identity.Data.AuthDbContext --files "Account.Register;Account.Login;Account.Logout"
#dotnet aspnet-codegenerator identity -lf --project $identitySolutionName
dotnet ef migrations add CreateIdentitySchema
dotnet ef database update

Write-Host  $identitySolutionName
cd ..

cd ..
Write-Host "All done! The solution '$($SolutionName).sln' has been created successfully."