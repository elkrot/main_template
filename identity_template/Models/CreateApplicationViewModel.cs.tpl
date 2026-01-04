using System.ComponentModel.DataAnnotations;

namespace {{Namespace}}.Models
{
    public class CreateApplicationViewModel
    {
        [Required(ErrorMessage = "Client ID обязателен")]
        [Display(Name = "Client ID (Уникальный идентификатор)")]
        public string ClientId { get; set; }

        [Required(ErrorMessage = "Название приложения обязательно")]
        [Display(Name = "Отображаемое имя")]
        public string DisplayName { get; set; }

        [Display(Name = "Client Secret (Пароль)")]
        public string ClientSecret { get; set; }

        [Display(Name = "Redirect URI (куда возвращать пользователя после входа)")]
        //[Url(ErrorMessage = "Введите корректный URL")]
        [RegularExpression(@"^https?://.+", ErrorMessage = "URL должен начинаться с http:// или https://")] 
        public string RedirectUri { get; set; }
        
        [Display(Name = "Тип клиента")]
        public string Type { get; set; } = "confidential"; // confidential или public
    }
}