using System.ComponentModel.DataAnnotations;

namespace $($identitySolutionName).Models
{
    public class ApplicationViewModel
{
	[Required]
    public string? ClientId { get; set; }
    public string? DisplayName { get; set; }
    [Required]
    [DataType(DataType.Password)]
    public string? ClientSecret { get; set; }
    public List<string> RedirectUris { get; set; } = new();
    public List<string> PostLogoutRedirectUris { get; set; } = new();
    public List<string> Permissions { get; set; } = new();
    public List<string> Requirements { get; set; } = new();
}

}