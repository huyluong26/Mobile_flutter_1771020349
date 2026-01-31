using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_Tournaments")]
public class Tournament : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }

    public TournamentFormat Format { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal EntryFee { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal PrizePool { get; set; }

    public TournamentStatus Status { get; set; } = TournamentStatus.Open;

    public string? Settings { get; set; } // JSON
}
