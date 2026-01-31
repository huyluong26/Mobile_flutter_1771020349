using backend.DTOs;
using backend.Models;
using backend.Repositories;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class WalletController : BaseController
{
    private readonly IWalletService _walletService;
    private readonly IRepository<Member> _memberRepo; // Direct repo for ID lookup

    public WalletController(IWalletService walletService, IRepository<Member> memberRepo)
    {
        _walletService = walletService;
        _memberRepo = memberRepo;
    }

    private async Task<int?> GetCurrentMemberId()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;
        var members = await _memberRepo.FindAsync(m => m.UserId == userId);
        return members.FirstOrDefault()?.Id;
    }

    [Authorize]
    [HttpPost("deposit")]
    public async Task<IActionResult> RequestDeposit([FromBody] DepositRequestDto model)
    {
        if (model.Amount <= 0) return BadRequest("Amount must be positive.");
        
        var memberId = await GetCurrentMemberId();
        if (memberId == null) return Unauthorized("Member account not found.");

        var transaction = await _walletService.RequestDepositAsync(memberId.Value, model.Amount, model.Description, model.ProofImageUrl);
        return Ok(new { Message = "Deposit request submitted.", TransactionId = transaction.Id });
    }

    [Authorize]
    [HttpGet("transactions")]
    public async Task<IActionResult> GetMyTransactions()
    {
        var memberId = await GetCurrentMemberId();
        if (memberId == null) return Unauthorized("Member account not found.");

        var history = await _walletService.GetMyTransactionsAsync(memberId.Value);
        return Ok(history);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("all")]
    public async Task<IActionResult> GetAllTransactions()
    {
        var history = await _walletService.GetAllTransactionsAsync();
        return Ok(history);
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("approve/{transactionId}")]
    public async Task<IActionResult> ApproveDeposit(int transactionId)
    {
        var success = await _walletService.ApproveDepositAsync(transactionId);
        if (!success) return BadRequest("Failed to approve transaction. It may not exist, be already processed, or is not a deposit.");
        
        return Ok(new { Message = "Transaction approved and balance updated." });
    }
}
