using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_Matches")]
public class Match : BaseEntity
{
    public int? TournamentId { get; set; }
    [ForeignKey("TournamentId")]
    public Tournament? Tournament { get; set; }

    public string? RoundName { get; set; } // Group A, Quarter Final...

    public DateTime? Date { get; set; }
    public TimeSpan? StartTime { get; set; } // Or use separate DateTime field

    // Participants (Simplified references, flexible for Singles/Doubles)
    public int? Team1_Player1Id { get; set; }
    public int? Team1_Player2Id { get; set; }
    
    public int? Team2_Player1Id { get; set; }
    public int? Team2_Player2Id { get; set; }

    // Results
    public int Score1 { get; set; }
    public int Score2 { get; set; }

    public string? Details { get; set; } // Set scores: "11-9, 5-11"

    public MatchWinningSide? WinningSide { get; set; }

    public bool IsRanked { get; set; }

    public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
}
