using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_Members")]
public class Member : BaseEntity
{
    [Required]
    public string FullName { get; set; } = string.Empty;

    public DateTime JoinDate { get; set; } = DateTime.UtcNow;

    public double RankLevel { get; set; }

    public bool IsActive { get; set; } = true;

    // Link to Identity User
    public string UserId { get; set; } = string.Empty;

    // Advanced
    [Column(TypeName = "decimal(18,2)")]
    public decimal WalletBalance { get; set; }

    public MemberTier Tier { get; set; } = MemberTier.Standard;

    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalSpent { get; set; }

    public string? AvatarUrl { get; set; }

    // Navigation properties can be added if needed, e.g. Transactions, Bookings
}
