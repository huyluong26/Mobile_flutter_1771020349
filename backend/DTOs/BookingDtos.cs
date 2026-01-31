using System.ComponentModel.DataAnnotations;
using backend.Enums;

namespace backend.DTOs;

public class CourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal PricePerHour { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public class BookingDto
{
    public int Id { get; set; }
    public int CourtId { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public decimal TotalPrice { get; set; }
    public string Status { get; set; } = string.Empty;
    public bool IsRecurring { get; set; }
    public int MemberId { get; set; }
    public string MemberName { get; set; } = string.Empty;
}

public class CreateBookingDto
{
    [Required]
    public int CourtId { get; set; }
    
    [Required]
    public DateTime StartTime { get; set; }
    
    [Required]
    public int DurationMinutes { get; set; } // e.g. 60, 90
    // OR EndTime
}

public class CreateRecurringBookingDto : CreateBookingDto
{
    [Required]
    public string RecurrenceRule { get; set; } = string.Empty; // "Weekly"
    
    [Required]
    public DateTime EndRecurrenceDate { get; set; }
}
