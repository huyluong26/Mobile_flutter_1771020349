using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models;

[Table("349_News")]
public class News : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool IsPinned { get; set; }
    public string? ImageUrl { get; set; }
}
