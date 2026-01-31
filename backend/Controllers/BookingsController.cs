using backend.DTOs;
using backend.Models;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BookingsController : BaseController
{
    private readonly IBookingService _bookingService;
    private readonly backend.Repositories.IRepository<Member> _memberRepo;

    public BookingsController(IBookingService bookingService, backend.Repositories.IRepository<Member> memberRepo)
    {
        _bookingService = bookingService;
        _memberRepo = memberRepo;
    }

    private async Task<int?> GetCurrentMemberId()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;
        var members = await _memberRepo.FindAsync(m => m.UserId == userId);
        return members.FirstOrDefault()?.Id;
    }

    [HttpGet("courts")]
    public async Task<IActionResult> GetCourts()
    {
        var courts = await _bookingService.GetCourtsAsync();
        // Map to simple DTO
        return Ok(courts.Select(c => new 
        { 
            c.Id, c.Name, c.Description, c.PricePerHour
        }));
    }

    [HttpGet("calendar")]
    public async Task<IActionResult> GetCalendar([FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var bookings = await _bookingService.GetCalendarAsync(from, to);
        return Ok(bookings);
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] CreateBookingDto dto)
    {
        var memberId = await GetCurrentMemberId();
        if (memberId == null) return Unauthorized();

        try
        {
            var booking = await _bookingService.CreateBookingAsync(memberId.Value, dto);
            return Ok(booking);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpPost("recurring")]
    public async Task<IActionResult> CreateRecurringBooking([FromBody] CreateRecurringBookingDto dto)
    {
        var memberId = await GetCurrentMemberId();
        if (memberId == null) return Unauthorized();

        try
        {
            var bookings = await _bookingService.CreateRecurringBookingAsync(memberId.Value, dto);
            return Ok(new { Message = $"Successfully created {bookings.Count()} bookings." });
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpPost("cancel/{id}")]
    public async Task<IActionResult> CancelBooking(int id)
    {
        var memberId = await GetCurrentMemberId();
        if (memberId == null) return Unauthorized();

        var result = await _bookingService.CancelBookingAsync(memberId.Value, id);
        if (!result) return BadRequest("Could not cancel booking (Invalid ID or Time restrictions).");

        return Ok(new { Message = "Booking cancelled successfully." });
    }

    // Admin Court Management
    [Authorize(Roles = "Admin")]
    [HttpPost("courts")]
    public async Task<IActionResult> CreateCourt([FromBody] CourtDto dto)
    {
        var court = new Court
        {
            Name = dto.Name,
            Description = dto.Description,
            PricePerHour = dto.PricePerHour,
            IsActive = true
        };
        await _bookingService.CreateCourtAsync(court);
        return Ok(court);
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("courts/{id}")]
    public async Task<IActionResult> UpdateCourt(int id, [FromBody] CourtDto dto)
    {
        var court = new Court
        {
            Id = id,
            Name = dto.Name,
            Description = dto.Description,
            PricePerHour = dto.PricePerHour,
            IsActive = dto.IsActive
        };
        var result = await _bookingService.UpdateCourtAsync(court);
        if (!result) return NotFound();
        return Ok(court);
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("courts/{id}")]
    public async Task<IActionResult> DeleteCourt(int id)
    {
        var result = await _bookingService.DeleteCourtAsync(id);
        if (!result) return NotFound();
        return Ok(new { Message = "Court deleted successfully." });
    }
}
