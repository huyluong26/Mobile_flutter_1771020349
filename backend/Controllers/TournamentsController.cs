using backend.DTOs;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TournamentsController : BaseController
{
    private readonly ITournamentService _tournamentService;
    private readonly backend.Repositories.IRepository<backend.Models.Member> _memberRepo;

    public TournamentsController(ITournamentService tournamentService, backend.Repositories.IRepository<backend.Models.Member> memberRepo)
    {
        _tournamentService = tournamentService;
        _memberRepo = memberRepo;
    }

    private async Task<int?> GetCurrentMemberId()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;
        var members = await _memberRepo.FindAsync(m => m.UserId == userId);
        return members.FirstOrDefault()?.Id;
    }

    [HttpGet]
    public async Task<IActionResult> GetTournaments()
    {
        var memberId = await GetCurrentMemberId();
        var list = await _tournamentService.GetTournamentsAsync(memberId);
        return Ok(list);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> CreateTournament([FromBody] CreateTournamentDto dto)
    {
        var t = await _tournamentService.CreateTournamentAsync(dto);
        return Ok(t);
    }

    [Authorize]
    [HttpPost("{id}/join")]
    public async Task<IActionResult> JoinTournament(int id, [FromBody] JoinTournamentDto dto)
    {
        var memberId = await GetCurrentMemberId();
        if (memberId == null) return Unauthorized();

        try
        {
            await _tournamentService.JoinTournamentAsync(memberId.Value, id, dto.TeamName);
            return Ok(new { Message = "Joined tournament successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Message = ex.Message });
        }
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{id}/generate-schedule")]
    public async Task<IActionResult> GenerateSchedule(int id)
    {
        try
        {
            await _tournamentService.GenerateScheduleAsync(id);
            return Ok(new { Message = "Schedule generated successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Message = ex.Message });
        }
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteTournament(int id)
    {
        try
        {
            var success = await _tournamentService.DeleteTournamentAsync(id);
            if (!success) return NotFound("Tournament not found.");
            return Ok(new { Message = "Tournament deleted successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Message = ex.Message });
        }
    }
}

[Route("api/matches")]
[ApiController]
public class MatchesController : BaseController
{
    private readonly ITournamentService _tournamentService;

    public MatchesController(ITournamentService tournamentService)
    {
        _tournamentService = tournamentService;
    }

    [Authorize(Roles = "Admin")] // Or Official
    [HttpPost("{id}/result")]
    public async Task<IActionResult> UpdateResult(int id, [FromBody] MatchResultDto dto)
    {
        var success = await _tournamentService.UpdateMatchResultAsync(id, dto);
        if (!success) return NotFound("Match not found.");
        return Ok(new { Message = "Match result updated and ranks calculated." });
    }
}
