using System.ComponentModel.DataAnnotations;

namespace $($identitySolutionName).Models
{
   public class ScopeViewModel
{
    public string? Name { get; set; }
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public List<string> Resources { get; set; } = new();
}
}