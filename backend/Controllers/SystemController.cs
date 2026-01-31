using backend.Models;
using backend.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class SystemController : ControllerBase
{
    private readonly UserManager<IdentityUser> _userManager;
    private readonly IRepository<Member> _memberRepo;

    public SystemController(UserManager<IdentityUser> userManager, IRepository<Member> memberRepo)
    {
        _userManager = userManager;
        _memberRepo = memberRepo;
    }

    // POST /api/system/promote-admin/5
    // WARNING: This is a backdoor for development only! Remove or secure this in production.
    [HttpPost("promote-admin/{memberId}")]
    public async Task<IActionResult> PromoteToAdmin(int memberId)
    {
        // 1. Find Member by ID (Business Logic ID)
        var member = await _memberRepo.GetByIdAsync(memberId);
        if (member == null) return NotFound($"Member with ID {memberId} not found.");

        // 2. Find Identity User by UserId link
        var user = await _userManager.FindByIdAsync(member.UserId);
        if (user == null) return NotFound("Linked system user not found.");

        // 3. Check if role Admin exists (It should be seeded)
        // Add to Role
        var result = await _userManager.AddToRoleAsync(user, "Admin");

        if (result.Succeeded)
        {
            return Ok(new { 
                Message = $"User '{user.UserName}' (MemberId: {memberId}) is now an Admin.",
                CurrentRoles = await _userManager.GetRolesAsync(user)
            });
        }

        return BadRequest(result.Errors);
    }
    [HttpPost("seed-courts")]
    public async Task<IActionResult> SeedCourts([FromServices] Data.AppDbContext context)
    {
        if (context.Courts.Any()) return Ok("Courts already exist.");

        context.Courts.AddRange(new List<Court>
        {
            new Court { Name = "Sân 1 (VIP)", PricePerHour = 100000, IsActive = true, Description = "Sân thảm xịn" },
            new Court { Name = "Sân 2 (Thường)", PricePerHour = 50000, IsActive = true, Description = "Sân bê tông" },
            new Court { Name = "Sân 3 (Thường)", PricePerHour = 50000, IsActive = true, Description = "Sân bê tông" }
        });
        await context.SaveChangesAsync();
        return Ok("Seeded 3 courts successfully.");
    }
}
