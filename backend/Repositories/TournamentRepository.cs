using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repositories;

public interface ITournamentRepository : IRepository<Tournament>
{
    // Specific logic like getting active tournaments
}

public class TournamentRepository : Repository<Tournament>, ITournamentRepository
{
    public TournamentRepository(Data.AppDbContext context) : base(context) { }
}

public interface IMatchRepository : IRepository<Match>
{
    Task<IEnumerable<Match>> GetMatchesByTournamentAsync(int tournamentId);
}

public class MatchRepository : Repository<Match>, IMatchRepository
{
    public MatchRepository(Data.AppDbContext context) : base(context) { }
    
    public async Task<IEnumerable<Match>> GetMatchesByTournamentAsync(int tournamentId)
    {
        return await _dbSet.Where(m => m.TournamentId == tournamentId).OrderBy(m => m.StartTime).ToListAsync();
    }
}
