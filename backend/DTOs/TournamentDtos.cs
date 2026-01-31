using System.ComponentModel.DataAnnotations;

namespace backend.DTOs;

public class CreateTournamentDto
{
    [Required]
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Format { get; set; } = "Knockout"; // Knockout, RoundRobin
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
}

public class TournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
    public string Format { get; set; } = string.Empty;
    public int ParticipantCount { get; set; }
    public bool IsJoined { get; set; }
}

public class JoinTournamentDto
{
    public string TeamName { get; set; } = string.Empty; // If team based
}

public class MatchResultDto
{
    public string Score { get; set; } = string.Empty; // "21-19, 21-18"
    public string WinningSide { get; set; } = "Team1"; // Team1 or Team2
    public int WinnerMemberId { get; set; } // If single
}
