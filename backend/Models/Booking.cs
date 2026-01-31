using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_Bookings")]
public class Booking : BaseEntity
{
    public int CourtId { get; set; }
    [ForeignKey("CourtId")]
    public Court? Court { get; set; }

    public int MemberId { get; set; }
    [ForeignKey("MemberId")]
    public Member? Member { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalPrice { get; set; }

    public int? TransactionId { get; set; }
    [ForeignKey("TransactionId")]
    public WalletTransaction? Transaction { get; set; }

    // Advanced
    public bool IsRecurring { get; set; }
    public string? RecurrenceRule { get; set; }
    public int? ParentBookingId { get; set; }

    public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;
}
