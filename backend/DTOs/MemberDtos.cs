using backend.Enums;

namespace backend.DTOs;

public class MemberDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty; // From Identity
    public DateTime JoinDate { get; set; }
    public double RankLevel { get; set; }
    public bool IsActive { get; set; }
    public string? AvatarUrl { get; set; }
    public MemberTier Tier { get; set; }
    public decimal WalletBalance { get; set; }
    public decimal TotalSpent { get; set; }
}

public class MemberProfileDto : MemberDto
{
    // Extended info for profile
    public IEnumerable<MatchHistoryDto> MatchHistory { get; set; } = new List<MatchHistoryDto>();
    // Rank history could be complex, for now maybe just current validation
}

public class MatchHistoryDto
{
    public int MatchId { get; set; }
    public string TournamentName { get; set; } = string.Empty;
    public DateTime? Date { get; set; }
    public string Result { get; set; } = string.Empty; // Win/Loss/Draw
    public string Score { get; set; } = string.Empty;
    public string OpponentName { get; set; } = string.Empty;
}

public class PagedResult<T>
{
    public IEnumerable<T> Items { get; set; } = new List<T>();
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
}
