using backend.Models;
using backend.Repositories;

namespace backend.Services;

public class Service<T> : IService<T> where T : BaseEntity
{
    protected readonly IRepository<T> _repository;

    public Service(IRepository<T> repository)
    {
        _repository = repository;
    }

    public virtual async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _repository.GetAllAsync();
    }

    public virtual async Task<T?> GetByIdAsync(int id)
    {
        return await _repository.GetByIdAsync(id);
    }

    public virtual async Task AddAsync(T entity)
    {
        await _repository.AddAsync(entity);
        await _repository.SaveChangesAsync();
    }

    public virtual async Task UpdateAsync(int id, T entity)
    {
        var existing = await _repository.GetByIdAsync(id);
        if (existing == null) throw new KeyNotFoundException("Entity not found");
        
        // This is a simplified update. Real mapping logic (DTO to Entity) usually happens in Controller or here.
        // For generic service, simple assignment might not work for all properties without reflection or AutoMapper.
        // We will assume the entity passed in is the one to update, but ID must match.
        if (entity.Id != id) entity.Id = id;

        await _repository.UpdateAsync(entity);
        await _repository.SaveChangesAsync();
    }

    public virtual async Task DeleteAsync(int id)
    {
        await _repository.DeleteAsync(id);
        await _repository.SaveChangesAsync();
    }
}
