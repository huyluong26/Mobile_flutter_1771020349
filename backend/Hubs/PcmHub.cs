using Microsoft.AspNetCore.SignalR;

namespace backend.Hubs;

/// <summary>
/// Pickleball Club Management Hub - Real-time communication
/// </summary>
public class PcmHub : Hub
{
    // ===== SERVER -> CLIENT METHODS =====
    // These are called via IHubContext<PcmHub> from Services
    
    // Client should listen to: "ReceiveNotification"
    // Payload: { type, message, linkUrl }
    
    // Client should listen to: "UpdateCalendar"
    // Payload: { courtId, date, bookings[] }
    
    // Client should listen to: "UpdateMatchScore"
    // Payload: { matchId, score, status, winningSide }

    // ===== CLIENT -> SERVER METHODS =====
    
    /// <summary>
    /// Join a group to receive targeted updates (e.g., "Tournament_5", "Court_1")
    /// </summary>
    public async Task JoinGroup(string groupName)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        await Clients.Caller.SendAsync("ReceiveNotification", new
        {
            type = "Info",
            message = $"Joined group: {groupName}",
            linkUrl = ""
        });
    }

    /// <summary>
    /// Leave a group
    /// </summary>
    public async Task LeaveGroup(string groupName)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
    }

    /// <summary>
    /// Override: Called when a client connects
    /// </summary>
    public override async Task OnConnectedAsync()
    {
        // Optional: Add user to a default group based on identity
        // var userId = Context.User?.Identity?.Name;
        // if (userId != null) await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{userId}");
        
        await base.OnConnectedAsync();
    }

    /// <summary>
    /// Override: Called when a client disconnects
    /// </summary>
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await base.OnDisconnectedAsync(exception);
    }
}

/// <summary>
/// Helper class for sending hub messages from Services
/// </summary>
public static class PcmHubMethods
{
    public const string ReceiveNotification = "ReceiveNotification";
    public const string UpdateCalendar = "UpdateCalendar";
    public const string UpdateMatchScore = "UpdateMatchScore";
}
