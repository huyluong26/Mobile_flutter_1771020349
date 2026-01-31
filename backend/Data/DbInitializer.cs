using Microsoft.AspNetCore.Identity;

namespace backend.Data;

public static class DbInitializer
{
    public static async Task SeedRoles(IServiceProvider serviceProvider)
    {
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = serviceProvider.GetRequiredService<UserManager<IdentityUser>>();
        var context = serviceProvider.GetRequiredService<AppDbContext>();

        // 1. Seed Roles
        string[] roleNames = { "Admin", "Member", "Staff" };

        foreach (var roleName in roleNames)
        {
            var roleExist = await roleManager.RoleExistsAsync(roleName);
            if (!roleExist)
            {
                await roleManager.CreateAsync(new IdentityRole(roleName));
            }
        }

        // 2. Seed Admin User
        var adminEmail = "admin@pickleball.com";
        var adminUser = await userManager.FindByEmailAsync(adminEmail);
        if (adminUser == null)
        {
            adminUser = new IdentityUser
            {
                UserName = "admin",
                Email = adminEmail,
                EmailConfirmed = true
            };
            var result = await userManager.CreateAsync(adminUser, "Admin@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");

                // Create Member Profile for Admin
                var adminMember = new backend.Models.Member
                {
                    UserId = adminUser.Id,
                    FullName = "System Admin",
                    JoinDate = DateTime.UtcNow,
                    RankLevel = 5.0, // Max rank for admin
                    IsActive = true,
                    WalletBalance = 0,
                    Tier = backend.Enums.MemberTier.Diamond
                };
                context.Members.Add(adminMember);
            }
        }

        // 3. Seed Standard User
        var userEmail = "user@pickleball.com";
        var normalUser = await userManager.FindByEmailAsync(userEmail);
        if (normalUser == null)
        {
            normalUser = new IdentityUser
            {
                UserName = "user",
                Email = userEmail,
                EmailConfirmed = true
            };
            var result = await userManager.CreateAsync(normalUser, "User@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(normalUser, "Member");

                // Create Member Profile for User
                var memberProfile = new backend.Models.Member
                {
                    UserId = normalUser.Id,
                    FullName = "Standard User",
                    JoinDate = DateTime.UtcNow,
                    RankLevel = 1.0, 
                    IsActive = true,
                    WalletBalance = 0,
                    Tier = backend.Enums.MemberTier.Standard
                };
                context.Members.Add(memberProfile);
            }
        }

        await context.SaveChangesAsync();
    }
}
