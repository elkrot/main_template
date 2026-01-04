using System.ComponentModel.DataAnnotations;

namespace {{Namespace}}.Models
{
    public class EditApplicationViewModel
    {
        [Required]
        public string Id { get; set; } // Внутренний ID (Guid)

        [Display(Name = "Client ID")]
        public string ClientId { get; set; } // Только для отображения

        [Required(ErrorMessage = "Название приложения обязательно")]
        [Display(Name = "Отображаемое имя")]
        public string DisplayName { get; set; }

        [Display(Name = "Новый Client Secret (оставьте пустым, чтобы не менять)")]
        public string? ClientSecret { get; set; }

        [Display(Name = "Redirect URI")]
        [RegularExpression(@"^https?://.+", ErrorMessage = "URL должен начинаться с http:// или https://")]
        public string RedirectUri { get; set; }

        [Display(Name = "Тип клиента")]
        public string Type { get; set; }
    }
}