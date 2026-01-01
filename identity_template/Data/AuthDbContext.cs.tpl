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