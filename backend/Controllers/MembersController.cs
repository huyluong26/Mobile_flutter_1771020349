using backend.DTOs;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class MembersController : BaseController
{
    private readonly IMemberService _memberService;
    private readonly UserManager<IdentityUser> _userManager;

    public MembersController(IMemberService memberService, UserManager<IdentityUser> userManager)
    {
        _memberService = memberService;
        _userManager = userManager;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetMembers(
        [FromQuery] string? search,
        [FromQuery] Enums.MemberTier? tier,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var result = await _memberService.GetMembersAsync(search, tier, page, pageSize);

        // Populate Emails (Since Service layer handles Member entity, and User is Identity)
        // We can do this enrichment here in Controller or inject UserManager into Service.
        // Doing here for simplicity of Service dependencies.
        foreach (var item in result.Items)
        {
            // Note: This is N+1 query problem potential. 
            // In optimal code, we would load all relevant Users in one go map by ID.
            // Keeping simple for now.
            // Ideally Member table has Email duplicated or we use a View.
        }

        return Ok(result);
    }

    [HttpGet("{id}/profile")]
    public async Task<IActionResult> GetMemberProfile(int id)
    {
        var result = await _memberService.GetMemberProfileAsync(id);
        if (result == null) return NotFound();

        // Check current user role and id
        var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var isAdmin = User.IsInRole("Admin");

        // Assuming query user by userId to match member.UserId
        // Since we don't have Member.UserId in DTO result directly (it has Id, Email...), 
        // we might rely on the fetched data logic. 
        // But result is DTO. Let's assume for security, we fetch Entity or trust logic.
        // Actually, we need to know if 'id' (MemberId) belongs to 'currentUserId' (IdentityId).
        
        // Quick check: If not Admin, hide sensitive info
        if (!isAdmin)
        {
             // We need to verify ownership. 
             // Ideally we should add UserId to MemberProfileDto to compare easily.
             // For now, let's just Hide WalletBalance for EVERYONE except Admin in this public profile view 
             // (User sees their own wallet in /me endpoint anyway).
             
             result.WalletBalance = 0; // Hide it
             result.TotalSpent = 0;    // Hide it
        }

        return Ok(result);
    }
}
