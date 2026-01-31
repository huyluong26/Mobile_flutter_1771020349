using backend.Models;
using backend.Repositories;
using backend.Enums;
using backend.DTOs;
using backend.Hubs;
using Microsoft.AspNetCore.SignalR;

namespace backend.Services;

public interface IBookingService
{
    Task<IEnumerable<Court>> GetCourtsAsync();
    Task<IEnumerable<BookingDto>> GetCalendarAsync(DateTime from, DateTime to);
    Task<Booking> CreateBookingAsync(int memberId, CreateBookingDto dto);
    Task<IEnumerable<Booking>> CreateRecurringBookingAsync(int memberId, CreateRecurringBookingDto dto);
    Task<bool> CancelBookingAsync(int memberId, int bookingId);
    
    // Court Management
    Task<Court> CreateCourtAsync(Court court);
    Task<bool> UpdateCourtAsync(Court court);
    Task<bool> DeleteCourtAsync(int courtId);
}

public class BookingService : IBookingService
{
    private readonly IBookingRepository _bookingRepo;
    private readonly ICourtRepository _courtRepo;
    private readonly IRepository<Member> _memberRepo;
    private readonly IRepository<WalletTransaction> _transactionRepo;
    private readonly IHubContext<PcmHub> _hubContext;

    public BookingService(
        IBookingRepository bookingRepo,
        ICourtRepository courtRepo,
        IRepository<Member> memberRepo,
        IRepository<WalletTransaction> transactionRepo,
        IHubContext<PcmHub> hubContext)
    {
        _bookingRepo = bookingRepo;
        _courtRepo = courtRepo;
        _memberRepo = memberRepo;
        _transactionRepo = transactionRepo;
        _hubContext = hubContext;
    }

    public async Task<IEnumerable<Court>> GetCourtsAsync()
    {
        return await _courtRepo.GetAllAsync();
    }

    public async Task<IEnumerable<BookingDto>> GetCalendarAsync(DateTime from, DateTime to)
    {
        var bookings = await _bookingRepo.GetConfirmBookingsInRangeAsync(from, to);
        
        return bookings.Select(b => new BookingDto
        {
            Id = b.Id,
            CourtId = b.CourtId,
            CourtName = b.Court?.Name ?? "Unknown",
            StartTime = b.StartTime,
            EndTime = b.EndTime,
            TotalPrice = b.TotalPrice,
            Status = b.Status.ToString(),
            IsRecurring = b.IsRecurring,
            MemberId = b.MemberId,
            MemberName = b.Member?.FullName ?? "Unknown"
        });
    }

    public async Task<Booking> CreateBookingAsync(int memberId, CreateBookingDto dto)
    {
        var court = await _courtRepo.GetByIdAsync(dto.CourtId);
        if (court == null || !court.IsActive) throw new Exception("Court not available.");

        var endTime = dto.StartTime.AddMinutes(dto.DurationMinutes);
        
        var overlap = await _bookingRepo.GetOverlappingBookingsAsync(dto.CourtId, dto.StartTime, endTime);
        if (overlap.Any()) throw new Exception("Court is already booked for this time.");

        decimal hours = (decimal)dto.DurationMinutes / 60;
        decimal totalPrice = court.PricePerHour * hours;

        var member = await _memberRepo.GetByIdAsync(memberId);
        if (member == null) throw new Exception("Member not found.");
        if (member.WalletBalance < totalPrice) throw new Exception("Insufficient wallet balance.");

        var transaction = new WalletTransaction
        {
            MemberId = memberId,
            Amount = -totalPrice,
            Type = WalletTransactionType.Payment,
            Status = WalletTransactionStatus.Completed,
            Description = $"Booking Court {court.Name} on {dto.StartTime}",
            CreatedAt = DateTime.UtcNow
        };
        await _transactionRepo.AddAsync(transaction);

        member.WalletBalance -= totalPrice;
        member.TotalSpent += totalPrice;
        await _memberRepo.UpdateAsync(member);

        var booking = new Booking
        {
            CourtId = dto.CourtId,
            MemberId = memberId,
            StartTime = dto.StartTime,
            EndTime = endTime,
            TotalPrice = totalPrice,
            Status = BookingStatus.Confirmed,
            Transaction = transaction
        };
        
        await _bookingRepo.AddAsync(booking);
        await _bookingRepo.SaveChangesAsync();

        // Broadcast calendar update via SignalR
        await _hubContext.Clients.All.SendAsync(PcmHubMethods.UpdateCalendar, new
        {
            courtId = dto.CourtId,
            date = dto.StartTime.Date,
            action = "BookingCreated",
            bookingId = booking.Id
        });

        return booking;
    }

    public async Task<IEnumerable<Booking>> CreateRecurringBookingAsync(int memberId, CreateRecurringBookingDto dto)
    {
        // 1. Check VIP/Tier logic if enforced
        var member = await _memberRepo.GetByIdAsync(memberId);
        if (member == null) throw new Exception("Member not found.");
        // Example logic: Only Gold+
        if (member.WalletBalance < 0) throw new Exception("Cannot book with negative balance."); 
        // Implementation of recurring is complex (loop dates).
        // Simplification: Loop weekly until EndRecurrenceDate.

        var bookings = new List<Booking>();
        var currentDate = dto.StartTime;
        var court = await _courtRepo.GetByIdAsync(dto.CourtId);
         if (court == null) throw new Exception("Court invalid.");

        decimal totalBatchPrice = 0;

        // Pre-calculation loop
        var dates = new List<DateTime>();
        while(currentDate <= dto.EndRecurrenceDate)
        {
            dates.Add(currentDate);
            currentDate = currentDate.AddDays(7); // Weekly
        }

        // Validate all slots and calculate total
        decimal hours = (decimal)dto.DurationMinutes / 60;
        decimal singlePrice = court.PricePerHour * hours;
        totalBatchPrice = singlePrice * dates.Count;

        if (member.WalletBalance < totalBatchPrice) throw new Exception($"Insufficient balance for {dates.Count} bookings. Total: {totalBatchPrice}");

        // Create transaction for FULL amount
        var transaction = new WalletTransaction
        {
             MemberId = memberId,
             Amount = -totalBatchPrice,
             Type = WalletTransactionType.Payment,
             Status = WalletTransactionStatus.Completed,
             Description = $"Recurring Booking ({dates.Count} slots)",
             CreatedAt = DateTime.UtcNow
        };
        await _transactionRepo.AddAsync(transaction);
        member.WalletBalance -= totalBatchPrice;
        member.TotalSpent += totalBatchPrice;
        await _memberRepo.UpdateAsync(member);

        // Create Bookings
        int? parentId = null;
        foreach (var start in dates)
        {
            var end = start.AddMinutes(dto.DurationMinutes);
             // Verify overlap for EACH slot using Repo
            var overlap = await _bookingRepo.GetOverlappingBookingsAsync(dto.CourtId, start, end);
            if (overlap.Any()) throw new Exception($"Conflict at {start}");

            var booking = new Booking
            {
                CourtId = dto.CourtId,
                MemberId = memberId,
                StartTime = start,
                EndTime = end,
                TotalPrice = singlePrice,
                Status = BookingStatus.Confirmed,
                IsRecurring = true,
                RecurrenceRule = "Weekly",
                Transaction = transaction,
                ParentBookingId = parentId // First one is null (or Parent), others link to it? Logic varies. 
                // Let's make first one Parent.
            };
            
            await _bookingRepo.AddAsync(booking);
            // Save to establish ID for Parent logic? 
            if (parentId == null)
            {
                 await _bookingRepo.SaveChangesAsync();
                 parentId = booking.Id;
            }
            else
            {
                booking.ParentBookingId = parentId;
            }
            bookings.Add(booking);
        }
        
        await _bookingRepo.SaveChangesAsync();
        return bookings;
    }

    public async Task<bool> CancelBookingAsync(int memberId, int bookingId)
    {
        Console.WriteLine($"[CancelBooking] Request for Booking {bookingId} by Member {memberId}");
        var booking = await _bookingRepo.GetByIdAsync(bookingId);
        if (booking == null) {
             Console.WriteLine("[CancelBooking] Booking not found");
             return false;
        }
        
        // Ownership check
        if (booking.MemberId != memberId) {
            Console.WriteLine($"[CancelBooking] Ownership fail: BookingMember {booking.MemberId} != Request {memberId}");
            return false; 
        }

        if (booking.Status == BookingStatus.Cancelled) {
             Console.WriteLine("[CancelBooking] Already Cancelled");
             return false;
        }

        // Hoàn 75% tiền - 25% phí hủy
        decimal refundAmount = booking.TotalPrice * 0.75m;
        Console.WriteLine($"[CancelBooking] Refund Amount: {refundAmount}");

        // Update Booking
        booking.Status = BookingStatus.Cancelled;
        await _bookingRepo.UpdateAsync(booking);
        
        await _bookingRepo.SaveChangesAsync();
        Console.WriteLine("[CancelBooking] Status updated to Cancelled and Saved");


        // Refund Transaction
        if (refundAmount > 0)
        {
            var member = await _memberRepo.GetByIdAsync(memberId);
            if (member != null)
            {
                 var refundTrans = new WalletTransaction
                 {
                    MemberId = memberId,
                    Amount = refundAmount,
                    Type = WalletTransactionType.Refund,
                    Status = WalletTransactionStatus.Completed,
                    Description = $"Refund for Booking {bookingId}",
                    CreatedAt = DateTime.UtcNow,
                    RelatedId = bookingId.ToString()
                 };
                 await _transactionRepo.AddAsync(refundTrans);
                 member.WalletBalance += refundAmount;
                 await _memberRepo.UpdateAsync(member);
            }
        }
        
        await _bookingRepo.SaveChangesAsync();

        // Broadcast calendar update via SignalR
        await _hubContext.Clients.All.SendAsync(PcmHubMethods.UpdateCalendar, new
        {
            courtId = booking.CourtId,
            date = booking.StartTime.Date,
            action = "BookingCancelled",
            bookingId = bookingId
        });

        return true;
    }

    public async Task<Court> CreateCourtAsync(Court court)
    {
        await _courtRepo.AddAsync(court);
        await _courtRepo.SaveChangesAsync();
        return court;
    }

    public async Task<bool> UpdateCourtAsync(Court court)
    {
        var existing = await _courtRepo.GetByIdAsync(court.Id);
        if (existing == null) return false;

        existing.Name = court.Name;
        existing.Description = court.Description;
        existing.PricePerHour = court.PricePerHour;
        existing.IsActive = court.IsActive;

        await _courtRepo.UpdateAsync(existing);
        await _courtRepo.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteCourtAsync(int courtId)
    {
        var existing = await _courtRepo.GetByIdAsync(courtId);
        if (existing == null) return false;

        await _courtRepo.DeleteAsync(courtId);
        await _courtRepo.SaveChangesAsync();
        return true;
    }
}
