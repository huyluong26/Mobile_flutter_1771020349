using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_WalletTransactions")]
public class WalletTransaction : BaseEntity
{
    public int MemberId { get; set; }
    
    [ForeignKey("MemberId")]
    public Member? Member { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    public WalletTransactionType Type { get; set; }

    public WalletTransactionStatus Status { get; set; } = WalletTransactionStatus.Pending;

    public string? RelatedId { get; set; } // ID of Booking or Tournament

    public string? Description { get; set; }
    public string? ProofImageUrl { get; set; }
}
