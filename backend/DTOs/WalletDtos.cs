namespace backend.DTOs;

public class DepositRequestDto
{
    public decimal Amount { get; set; }
    public string? Description { get; set; }
    // In real app, we might handle file upload for proof image here (IFormFile)
    // For this exam/code-first DB scope, we can simulate with a URL string or just record text
    public string? ProofImageUrl { get; set; } 
}

public class WalletTransactionDto
{
    public int Id { get; set; }
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string? Description { get; set; }
    public string? RelatedId { get; set; }
    public string? MemberName { get; set; }
    public string? ProofImageUrl { get; set; }
}
