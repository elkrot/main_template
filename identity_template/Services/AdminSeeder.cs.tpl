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