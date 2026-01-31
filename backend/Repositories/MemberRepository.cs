using backend.Models;
using backend.Enums;

namespace backend.Repositories;

public interface IMemberRepository : IRepository<Member>
{
    Task<IEnumerable<Member>> GetMembersAdvancedAsync(string? search, MemberTier? tier);
}

public class MemberRepository : Repository<Member>, IMemberRepository
{
    public MemberRepository(Data.AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Member>> GetMembersAdvancedAsync(string? search, MemberTier? tier)
    {
        var query = _dbSet.AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            search = search.ToLower();
            // EF Core filtering
            query = query.Where(m => m.FullName.ToLower().Contains(search));
        }

        if (tier.HasValue)
        {
            query = query.Where(m => m.Tier == tier.Value);
        }

        // We can add OrderBy, Include here comfortably using EF Core
        return await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(query);
    }
}
