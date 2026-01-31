using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models;

[Table("349_Courts")]
public class Court : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal PricePerHour { get; set; }
}
