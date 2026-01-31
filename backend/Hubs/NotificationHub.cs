using Microsoft.AspNetCore.SignalR;

namespace backend.Hubs;

public class NotificationHub : Hub
{
    // Basic method to send notification to a user
    public async Task SendNotification(string userId, string message)
    {
        await Clients.User(userId).SendAsync("ReceiveNotification", message);
    }
}
