using backend.Models;
using backend.Repositories;
using backend.DTOs;
using backend.Enums;
using Microsoft.EntityFrameworkCore;

namespace backend.Services;

public interface IWalletService
{
    Task<WalletTransaction> RequestDepositAsync(int memberId, decimal amount, string? description, string? proofUrl);
    Task<IEnumerable<WalletTransactionDto>> GetMyTransactionsAsync(int memberId);
    Task<IEnumerable<WalletTransactionDto>> GetAllTransactionsAsync();
    Task<bool> ApproveDepositAsync(int transactionId);
}

public class WalletService : IWalletService
{
    private readonly IRepository<WalletTransaction> _transactionRepo;
    private readonly IRepository<Member> _memberRepo;
    // We treat wallet operations as critical, so using Repos directly to ensure transaction atomicity if needed.
    // In complex systems, UnitOfWork is preferred. Currently EF Core SaveChanges is transactional enough for single Context.

    public WalletService(IRepository<WalletTransaction> transactionRepo, IRepository<Member> memberRepo)
    {
        _transactionRepo = transactionRepo;
        _memberRepo = memberRepo;
    }

    public async Task<WalletTransaction> RequestDepositAsync(int memberId, decimal amount, string? description, string? proofUrl)
    {
        var transaction = new WalletTransaction
        {
            MemberId = memberId,
            Amount = amount,
            Type = WalletTransactionType.Deposit,
            Status = WalletTransactionStatus.Pending,
            Description = description,
            ProofImageUrl = proofUrl
        };

        await _transactionRepo.AddAsync(transaction);
        await _transactionRepo.SaveChangesAsync();
        return transaction;
    }

    public async Task<IEnumerable<WalletTransactionDto>> GetMyTransactionsAsync(int memberId)
    {
        var transactions = await _transactionRepo.FindAsync(t => t.MemberId == memberId);
        // Mapping with Member name
        var member = await _memberRepo.GetByIdAsync(memberId);
        
        return transactions.OrderByDescending(t => t.CreatedAt).Select(t => new WalletTransactionDto
        {
            Id = t.Id,
            Amount = t.Amount,
            Type = t.Type.ToString(),
            Status = t.Status.ToString(),
            CreatedAt = t.CreatedAt,
            Description = t.Description,
            RelatedId = t.RelatedId,
            MemberName = member?.FullName,
            ProofImageUrl = t.ProofImageUrl
        });
    }

    public async Task<IEnumerable<WalletTransactionDto>> GetAllTransactionsAsync()
    {
        // Simple join using DbSet since Repository might not expose IQueryable easily
        // But let's see if we can use Repos
        var transactions = await _transactionRepo.GetAllAsync();
        var dtos = new List<WalletTransactionDto>();
        
        foreach (var t in transactions.OrderByDescending(x => x.CreatedAt))
        {
            var m = await _memberRepo.GetByIdAsync(t.MemberId);
            dtos.Add(new WalletTransactionDto
            {
                Id = t.Id,
                Amount = t.Amount,
                Type = t.Type.ToString(),
                Status = t.Status.ToString(),
                CreatedAt = t.CreatedAt,
                Description = t.Description,
                RelatedId = t.RelatedId,
                MemberName = m?.FullName,
                ProofImageUrl = t.ProofImageUrl
            });
        }
        return dtos;
    }

    public async Task<bool> ApproveDepositAsync(int transactionId)
    {
        var transaction = await _transactionRepo.GetByIdAsync(transactionId);
        if (transaction == null || transaction.Status != WalletTransactionStatus.Pending || transaction.Type != WalletTransactionType.Deposit)
        {
            return false;
        }

        var member = await _memberRepo.GetByIdAsync(transaction.MemberId);
        if (member == null) return false;

        // Transactional Logic: Update Status AND Update Balance
        // For EF Core, sharing same context instance typically wraps changes in transaction on SaveChangesAsync.
        // If Services use scoped Repos sharing same Context (default in .NET DI), this works.

        transaction.Status = WalletTransactionStatus.Completed;
        transaction.UpdatedAt = DateTime.UtcNow; // UpdatedAt from BaseEntity

        member.WalletBalance += transaction.Amount;
        // Logic for Tier advancement based on TotalSpent? 
        // Deposits usually don't count as Spent. Spending on Booking does.
        
        await _transactionRepo.UpdateAsync(transaction);
        await _memberRepo.UpdateAsync(member);
        
        // This save might be called twice if underlying Repo saves immediately. 
        // Our Repo.UpdateAsync does NOT save immediately? 
        // Checking Step 17: Repository.UpdateAsync calls _dbSet.Update but NO SaveChanges. 
        // BUT Generic Service.UpdateAsync DOES Call SaveChanges.
        // Here we are in WalletService using REPOSITORY directly.
        // Repository pattern in Step 17: AddAsync DOES NOT SAVE? Wait.
        // Step 17 AddAsync: "await _dbSet.AddAsync(entity);" -> NO SaveChanges.
        // Step 17 UpdateAsync: "_dbSet.Update(entity);" -> NO SaveChanges.
        // Wait, Step 19 (Service) calls _repository.SaveChangesAsync().
        
        // So here in WalletService, we need to call SaveChanges on one of them?
        // Since they share Context, calling SaveChanges on any repo works.
        // Let's call it on transaction repo.
        
        await _transactionRepo.SaveChangesAsync(); 
        
        return true;
    }
}
