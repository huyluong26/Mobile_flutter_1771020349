using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models;

[Table("349_TournamentParticipants")]
public class TournamentParticipant : BaseEntity
{
    public int TournamentId { get; set; }
    [ForeignKey("TournamentId")]
    public Tournament? Tournament { get; set; }

    public int MemberId { get; set; }
    [ForeignKey("MemberId")]
    public Member? Member { get; set; }

    public string? TeamName { get; set; } // Optional if single
    public bool PaymentStatus { get; set; } // Has paid entry fee
}
