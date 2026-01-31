using backend.Models;
using backend.Repositories;
using backend.DTOs;
using backend.Enums;
using Microsoft.EntityFrameworkCore;

namespace backend.Services;

public interface IMemberService : IService<Member>
{
    Task<PagedResult<MemberDto>> GetMembersAsync(string? search, MemberTier? tier, int page, int pageSize);
    Task<MemberProfileDto?> GetMemberProfileAsync(int id);
}

public class MemberService : Service<Member>, IMemberService
{
    private readonly IMemberRepository _memberRepo;

    public MemberService(IMemberRepository repository) : base(repository)
    {
        _memberRepo = repository;
    }

    public async Task<PagedResult<MemberDto>> GetMembersAsync(string? search, MemberTier? tier, int page, int pageSize)
    {
        // Now using specific Repository method!
        // Note: Pagination logic can also be moved to Repository if desired (e.g. GetPagedMembers)
        // For now, we fetch filtered list from Repo and page in Service or filtering in Repo.
        // Let's use the new Repo method which Filtered in DB.
        
        var filteredMembers = await _memberRepo.GetMembersAdvancedAsync(search, tier);
        
        int total = filteredMembers.Count();
        var pagedItems = filteredMembers
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        // Note: The Generic Repository 'FindAsync' implementation in Step 18 returns IEnumerable (already executed query).
        // So filtering "query" here is doing it in Memory. This is fine for small apps but for big apps Repository should return IQueryable.
        // Assuming small dataset for this exam.

        var dtos = pagedItems.Select(member => new MemberDto
        {
            Id = member.Id,
            FullName = member.FullName,
            // Email is in Identity User, separating concerns usually means Service fetches User data too 
            // OR we join tables. Since they are decoupled, we might need a Helper to fetch User emails, 
            // or pass UserManager into this Service (acceptable).
            JoinDate = member.JoinDate,
            RankLevel = member.RankLevel,
            IsActive = member.IsActive,
            AvatarUrl = member.AvatarUrl,
            Tier = member.Tier,
            WalletBalance = member.WalletBalance,
            TotalSpent = member.TotalSpent
        }).ToList();

        return new PagedResult<MemberDto>
        {
            Items = dtos,
            TotalCount = total,
            PageNumber = page,
            PageSize = pageSize
        };
    }

    public async Task<MemberProfileDto?> GetMemberProfileAsync(int id)
    {
        var member = await _repository.GetByIdAsync(id);
        if (member == null) return null;

        return new MemberProfileDto
        {
            Id = member.Id,
            FullName = member.FullName,
            JoinDate = member.JoinDate,
            RankLevel = member.RankLevel,
            IsActive = member.IsActive,
            AvatarUrl = member.AvatarUrl,
            Tier = member.Tier,
            WalletBalance = member.WalletBalance,
            TotalSpent = member.TotalSpent,
            MatchHistory = new List<MatchHistoryDto>() // Populate later
        };
    }
}
