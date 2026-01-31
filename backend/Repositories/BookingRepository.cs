using backend.Models;
using backend.Enums;
using Microsoft.EntityFrameworkCore;

namespace backend.Repositories;

public interface IBookingRepository : IRepository<Booking>
{
    Task<IEnumerable<Booking>> GetOverlappingBookingsAsync(int courtId, DateTime start, DateTime end);
    Task<IEnumerable<Booking>> GetConfirmBookingsInRangeAsync(DateTime from, DateTime to);
}

public class BookingRepository : Repository<Booking>, IBookingRepository
{
    public BookingRepository(Data.AppDbContext context) : base(context) { }

    public async Task<IEnumerable<Booking>> GetOverlappingBookingsAsync(int courtId, DateTime start, DateTime end)
    {
        return await _dbSet.Where(b => 
            b.CourtId == courtId && 
            b.StartTime < end && 
            b.EndTime > start &&
            b.Status != BookingStatus.Cancelled
        ).ToListAsync();
    }

    public async Task<IEnumerable<Booking>> GetConfirmBookingsInRangeAsync(DateTime from, DateTime to)
    {
         return await _dbSet
            .Include(b => b.Court)  // Eager load details now!
            .Include(b => b.Member)
            .Where(b => b.StartTime < to && b.EndTime > from) // Lấy TÂT CẢ status để client xử lý hiển thị
            .ToListAsync();
    }
}
