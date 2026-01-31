namespace backend.Enums;

public enum MemberTier
{
    Standard,
    Silver,
    Gold,
    Diamond
}

public enum WalletTransactionType
{
    Deposit,
    Withdraw,
    Payment,
    Refund,
    Reward
}

public enum WalletTransactionStatus
{
    Pending,
    Completed,
    Rejected,
    Failed
}

public enum TransactionCategoryType
{
    Income, // Thu
    Expense // Chi
}

public enum BookingStatus
{
    PendingPayment,
    Confirmed,
    Cancelled,
    Completed
}

public enum TournamentFormat
{
    RoundRobin,
    Knockout,
    Hybrid
}

public enum TournamentStatus
{
    Open,
    Registering,
    DrawCompleted,
    Ongoing,
    Finished
}

public enum MatchWinningSide
{
    Team1,
    Team2
}

public enum MatchStatus
{
    Scheduled,
    InProgress,
    Finished
}

public enum NotificationType
{
    Info,
    Success,
    Warning
}
