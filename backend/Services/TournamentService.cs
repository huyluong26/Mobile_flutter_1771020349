using backend.Models;
using backend.Repositories;
using backend.DTOs;
using backend.Enums;
using backend.Hubs;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;

namespace backend.Services;

public interface ITournamentService
{
    Task<Tournament> CreateTournamentAsync(CreateTournamentDto dto);
    Task<bool> JoinTournamentAsync(int memberId, int tournamentId, string teamName);
    Task<bool> GenerateScheduleAsync(int tournamentId);
    Task<bool> UpdateMatchResultAsync(int matchId, MatchResultDto dto);
    Task<IEnumerable<TournamentDto>> GetTournamentsAsync(int? memberId = null);
    Task<bool> DeleteTournamentAsync(int id);
}

public class TournamentService : ITournamentService
{
    private readonly ITournamentRepository _tournamentRepo;
    private readonly IMatchRepository _matchRepo;
    private readonly IRepository<TournamentParticipant> _participantRepo;
    private readonly IRepository<Member> _memberRepo;
    private readonly IRepository<WalletTransaction> _transactionRepo;
    private readonly IHubContext<PcmHub> _hubContext;

    public TournamentService(
        ITournamentRepository tournamentRepo,
        IMatchRepository matchRepo,
        IRepository<TournamentParticipant> participantRepo,
        IRepository<Member> memberRepo,
        IRepository<WalletTransaction> transactionRepo,
        IHubContext<PcmHub> hubContext)
    {
        _tournamentRepo = tournamentRepo;
        _matchRepo = matchRepo;
        _participantRepo = participantRepo;
        _memberRepo = memberRepo;
        _transactionRepo = transactionRepo;
        _hubContext = hubContext;
    }

    public async Task<IEnumerable<TournamentDto>> GetTournamentsAsync(int? memberId = null)
    {
        // Add Include for participants to count?
        // Generic GetAll usually lazy or no include.
        // For simplicity, we assume small number.
        // In real app, Repo should return Projection DTO via Select to avoid fetching all data.
        var tournaments = await _tournamentRepo.GetAllAsync();
        var dtos = new List<TournamentDto>();

        foreach (var t in tournaments)
        {
            var participants = await _participantRepo.FindAsync(p => p.TournamentId == t.Id);
            dtos.Add(new TournamentDto
            {
                Id = t.Id,
                Name = t.Name,
                StartDate = t.StartDate,
                EndDate = t.EndDate,
                Status = t.Status.ToString(),
                EntryFee = t.EntryFee,
                PrizePool = t.PrizePool,
                Format = t.Format.ToString(),
                ParticipantCount = participants.Count(),
                IsJoined = memberId.HasValue && participants.Any(p => p.MemberId == memberId.Value)
            });
        }
        return dtos;
    }

    public async Task<Tournament> CreateTournamentAsync(CreateTournamentDto dto)
    {
// Fix Enum Mismatches
// TournamentStatus.Upcoming -> Registering (or Open)
// MatchStatus.Completed -> Finished

        var tournament = new Tournament
        {
            Name = dto.Name,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Format = Enum.TryParse<TournamentFormat>(dto.Format, out var fmt) ? fmt : TournamentFormat.Knockout,
            EntryFee = dto.EntryFee,
            PrizePool = dto.PrizePool,
            Status = TournamentStatus.Registering 
        };
        await _tournamentRepo.AddAsync(tournament);
        await _tournamentRepo.SaveChangesAsync();
        return tournament;
    }

    public async Task<bool> JoinTournamentAsync(int memberId, int tournamentId, string teamName)
    {
        var tournament = await _tournamentRepo.GetByIdAsync(tournamentId);
        if (tournament == null || (tournament.Status != TournamentStatus.Registering && tournament.Status != TournamentStatus.Open)) 
            throw new Exception("Giải đấu không hoạt động hoặc đã đóng đăng ký.");

        // Check already joined
        var existing = await _participantRepo.FindAsync(p => p.TournamentId == tournamentId && p.MemberId == memberId);
        if (existing.Any()) throw new Exception("Bạn đã tham gia giải đấu này rồi.");

        var member = await _memberRepo.GetByIdAsync(memberId);
        if (member == null) throw new Exception("Không tìm thấy thông tin thành viên.");

        // Check Wallet for Entry Fee
        if (member.WalletBalance < tournament.EntryFee) throw new Exception("Số dư ví không đủ để thanh toán phí tham gia.");

        // Deduct Fee
        if (tournament.EntryFee > 0)
        {
            var tx = new WalletTransaction
            {
                MemberId = memberId,
                Amount = -tournament.EntryFee,
                Type = WalletTransactionType.Payment,
                Status = WalletTransactionStatus.Completed,
                Description = $"Entry Fee for {tournament.Name}",
                CreatedAt = DateTime.UtcNow
            };
            await _transactionRepo.AddAsync(tx);
            
            member.WalletBalance -= tournament.EntryFee;
            member.TotalSpent += tournament.EntryFee;
            await _memberRepo.UpdateAsync(member);
            
            // Force save wallet deduction immediately
            await _transactionRepo.SaveChangesAsync();
        }

        // Add Participant
        var p = new TournamentParticipant
        {
            TournamentId = tournamentId,
            MemberId = memberId,
            TeamName = string.IsNullOrEmpty(teamName) ? member.FullName : teamName,
            PaymentStatus = true
        };
        await _participantRepo.AddAsync(p);
        await _participantRepo.SaveChangesAsync();

        return true;
    }

    public async Task<bool> GenerateScheduleAsync(int tournamentId)
    {
        var tournament = await _tournamentRepo.GetByIdAsync(tournamentId);
        if (tournament == null) return false;

        var participants = (await _participantRepo.FindAsync(p => p.TournamentId == tournamentId)).ToList();
        if (participants.Count < 2) throw new Exception("Not enough participants.");

        // Simplified Auto-Scheduler: Single Elimination Knockout
        // Logic: Pair 1vs2, 3vs4...
        // 1. Shuffle
        var rand = new Random();
        participants = participants.OrderBy(x => rand.Next()).ToList();

        int matchCount = participants.Count / 2;
        for (int i = 0; i < matchCount; i++)
        {
            var p1 = participants[i * 2];
            var p2 = participants[i * 2 + 1];

            // Note: Match Model (Step 50) has Team1Id, Team2Id? 
            // In Step 50 Model Match.cs has: Team1_Player1Id, Team2_Player1Id...
            // Assuming Singles for simplicity.
            
            var match = new Match
            {
                TournamentId = tournamentId,
                RoundName = "Round 1",
                Date = tournament.StartDate,
                IsRanked = true,
                Status = MatchStatus.Scheduled,
                Team1_Player1Id = p1.MemberId,
                Team2_Player1Id = p2.MemberId
                // Team Names could be stored if Model supports it
            };
            await _matchRepo.AddAsync(match);
        }

        tournament.Status = TournamentStatus.Ongoing;
        await _tournamentRepo.UpdateAsync(tournament);
        await _tournamentRepo.SaveChangesAsync();
        
        return true;
    }

    public async Task<bool> UpdateMatchResultAsync(int matchId, MatchResultDto dto)
    {
        var match = await _matchRepo.GetByIdAsync(matchId);
        if (match == null) return false;

        match.Details = dto.Score; // Store score string in Details
        // Parse "Team1" or "Team2" string to Enum
        if (Enum.TryParse<MatchWinningSide>(dto.WinningSide, out var side))
        {
            match.WinningSide = side;
        }
        match.Status = MatchStatus.Finished;

        // DUPR Logic (Simple ELO-like stub)
        // 1. Get Players
        // 2. Adjust RankLevel
        if (match.IsRanked)
        {
            var winnerId = (match.WinningSide == MatchWinningSide.Team1) ? match.Team1_Player1Id : match.Team2_Player1Id;
            var loserId = (match.WinningSide == MatchWinningSide.Team1) ? match.Team2_Player1Id : match.Team1_Player1Id;

            if (winnerId.HasValue && loserId.HasValue)
            {
                var winner = await _memberRepo.GetByIdAsync(winnerId.Value);
                var loser = await _memberRepo.GetByIdAsync(loserId.Value);
                
                if (winner != null && loser != null)
                {
                    // Calculation logic...
                    winner.RankLevel += 0.1; 
                    loser.RankLevel -= 0.05;
                    await _memberRepo.UpdateAsync(winner);
                    await _memberRepo.UpdateAsync(loser);
                }
            }
        }
        
        // Progression Logic (Create next round match)
        // This is complex (needs bracket tree knowledge). 
        // Skipped for MVP. 

        await _matchRepo.UpdateAsync(match);
        await _matchRepo.SaveChangesAsync();

        // Broadcast match score update via SignalR
        await _hubContext.Clients.Group($"Tournament_{match.TournamentId}").SendAsync(PcmHubMethods.UpdateMatchScore, new
        {
            matchId = matchId,
            score = dto.Score,
            status = match.Status.ToString(),
            winningSide = match.WinningSide?.ToString()
        });

        // Also broadcast to all clients
        await _hubContext.Clients.All.SendAsync(PcmHubMethods.UpdateMatchScore, new
        {
            matchId = matchId,
            tournamentId = match.TournamentId,
            score = dto.Score,
            status = match.Status.ToString(),
            winningSide = match.WinningSide?.ToString()
        });

        return true;
    }

    public async Task<bool> DeleteTournamentAsync(int id)
    {
        var tournament = await _tournamentRepo.GetByIdAsync(id);
        if (tournament == null) return false;
        
        await _tournamentRepo.DeleteAsync(id);
        await _tournamentRepo.SaveChangesAsync();
        return true;
    }
}
