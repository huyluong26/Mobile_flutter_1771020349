using backend.Models;

namespace backend.Repositories;

public interface ICourtRepository : IRepository<Court>
{
    // Add specific methods if needed, e.g. GetAvailableCourts...
}

public class CourtRepository : Repository<Court>, ICourtRepository
{
    public CourtRepository(Data.AppDbContext context) : base(context) { }
}
