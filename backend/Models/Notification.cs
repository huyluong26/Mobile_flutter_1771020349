using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_Notifications")]
public class Notification : BaseEntity
{
    public int ReceiverId { get; set; }
    // Assuming Receiver is a Member. If it's a User, this might be a string UserId. 
    // Request says "ReceiverId (FK)", referring to Members context mostly or Users.
    // Given the rest of the app is member-centric, assuming MemberId. 
    // However, if it's system-wide user notification, might need mapping.
    // I will map to Member for now as it's consistent with other FKs.
    [ForeignKey("ReceiverId")]
    public Member? Receiver { get; set; }

    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public string? LinkUrl { get; set; }
    public bool IsRead { get; set; }
}
