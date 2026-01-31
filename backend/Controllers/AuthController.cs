using backend.DTOs;
using backend.Hubs;
using backend.Models;
using backend.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : BaseController
{
    private readonly UserManager<IdentityUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly SignInManager<IdentityUser> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly IRepository<Member> _memberRepo;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly IWebHostEnvironment _env;

    public AuthController(
        UserManager<IdentityUser> userManager,
        RoleManager<IdentityRole> roleManager,
        SignInManager<IdentityUser> signInManager,
        IConfiguration configuration,
        IRepository<Member> memberRepo,
        IHubContext<NotificationHub> hubContext,
        IWebHostEnvironment env)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _memberRepo = memberRepo;
        _hubContext = hubContext;
        _env = env;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = new IdentityUser
        {
            UserName = model.Username,
            Email = model.Email
        };

        var result = await _userManager.CreateAsync(user, model.Password);

        if (result.Succeeded)
        {
            // Ensure Member role exists
            if (!await _roleManager.RoleExistsAsync("Member"))
                await _roleManager.CreateAsync(new IdentityRole("Member"));

            // Create Member entity linked to IdentityUser
            var member = new Member
            {
                FullName = model.FullName,
                UserId = user.Id,
                JoinDate = DateTime.UtcNow,
                IsActive = true,
                WalletBalance = 0,
                Tier = Enums.MemberTier.Standard
            };
            await _memberRepo.AddAsync(member);
            await _memberRepo.SaveChangesAsync();

            // Assign Default Role
            await _userManager.AddToRoleAsync(user, "Member");

            // Auto-promote 'admin' user if registered
            if (model.Username.ToLower() == "admin")
            {
                if (!await _roleManager.RoleExistsAsync("Admin"))
                    await _roleManager.CreateAsync(new IdentityRole("Admin"));
                await _userManager.AddToRoleAsync(user, "Admin");
            }

            return Ok(new { Message = "User registered successfully" });
        }

        return BadRequest(result.Errors);
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = await _userManager.FindByNameAsync(model.Username);
        if (user != null && await _userManager.CheckPasswordAsync(user, model.Password))
        {
            // Auto-promote 'admin' user on login if missed during register
            if (model.Username.ToLower() == "admin")
            {
                if (!await _roleManager.RoleExistsAsync("Admin"))
                    await _roleManager.CreateAsync(new IdentityRole("Admin"));
                
                if (!await _userManager.IsInRoleAsync(user, "Admin"))
                    await _userManager.AddToRoleAsync(user, "Admin");
            }

            var userRoles = await _userManager.GetRolesAsync(user);

            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Id)
            };

            foreach (var role in userRoles)
            {
                authClaims.Add(new Claim(ClaimTypes.Role, role));
            }

            var token = GetToken(authClaims);

            return Ok(new TokenResponseDto
            {
                Token = new JwtSecurityTokenHandler().WriteToken(token),
                ValidTo = token.ValidTo.ToString(),
                Username = user.UserName!,
                Email = user.Email!
            });
        }

        return Unauthorized();
    }

    private JwtSecurityToken GetToken(List<Claim> authClaims)
    {
        var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            expires: DateTime.Now.AddHours(3),
            claims: authClaims,
            signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
        );

        return token;
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var members = await _memberRepo.FindAsync(m => m.UserId == userId);
        var member = members.FirstOrDefault();

        if (member == null) return NotFound("Member profile not found");

        var user = await _userManager.FindByIdAsync(userId);
        
        if (user == null) return NotFound("User identity not found");
        
        // Get roles directly from UserManager to be accurate
        var roles = await _userManager.GetRolesAsync(user);
        var primaryRole = roles.Contains("Admin") ? "Admin" : roles.FirstOrDefault();

        return Ok(new
        {
            Id = member.Id,
            UserId = userId,
            FullName = member.FullName,
            Username = user?.UserName,
            Email = user?.Email,
            WalletBalance = member.WalletBalance,
            Tier = member.Tier.ToString(),
            AvatarUrl = member.AvatarUrl,
            Role = primaryRole // Return actual role
        });
    }

    [Authorize]
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto model)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var members = await _memberRepo.FindAsync(m => m.UserId == userId);
        var member = members.FirstOrDefault();

        if (member == null) return NotFound("Member profile not found");

        if (!string.IsNullOrEmpty(model.FullName))
        {
            member.FullName = model.FullName;
        }

        if (model.AvatarUrl != null)
        {
            member.AvatarUrl = model.AvatarUrl;
        }

        await _memberRepo.UpdateAsync(member);
        await _memberRepo.SaveChangesAsync(); // Lưu thay đổi vào database

        return Ok(new { Message = "Profile updated successfully", Member = member });
    }

    [Authorize]
    [HttpPost("upload-avatar")]
    public async Task<IActionResult> UploadAvatar(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded");

        // Validate file type (optional but recommended)
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(extension))
            return BadRequest("Invalid file type");

        // Sửa lỗi: WebRootPath đã là path đến wwwroot, không cần thêm "wwwroot" lần nữa
        var webRoot = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var uploadsFolder = Path.Combine(webRoot, "uploads");
        if (!Directory.Exists(uploadsFolder))
            Directory.CreateDirectory(uploadsFolder);

        var uniqueFileName = $"{Guid.NewGuid()}{extension}";
        var filePath = Path.Combine(uploadsFolder, uniqueFileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Return URL relative to server root
        var url = $"/uploads/{uniqueFileName}";
        return Ok(new { Url = url });
    }
}
