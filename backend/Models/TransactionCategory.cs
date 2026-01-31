using System.ComponentModel.DataAnnotations.Schema;
using backend.Enums;

namespace backend.Models;

[Table("349_TransactionCategories")]
public class TransactionCategory : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public TransactionCategoryType Type { get; set; } // Thu/Chi
}
