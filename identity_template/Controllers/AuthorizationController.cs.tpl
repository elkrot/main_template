using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using OpenIddict.Abstractions;
using OpenIddict.Server.AspNetCore;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore;

namespace {{Namespace}}.Controllers
{
    public class AuthorizationController : Controller
    {
        // Минимальная реализация для Client Credentials Flow (Machine-to-Machine)
        // Для логина пользователей (Code Flow) нужен более сложный код с SignInManager
        
        [HttpPost("~/connect/token")]
        public async Task<IActionResult> Exchange()
        {
            var request = HttpContext.GetOpenIddictServerRequest() 
                          ?? throw new InvalidOperationException("The OpenID Connect request cannot be retrieved.");

            if (request.IsClientCredentialsGrantType())
            {
                var identity = new ClaimsIdentity(OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);

                // Добавляем Subject (обязательно)
                identity.AddClaim(OpenIddictConstants.Claims.Subject, request.ClientId ?? "unknown_client");

                var principal = new ClaimsPrincipal(identity);
                
                // Устанавливаем scopes
                principal.SetScopes(request.GetScopes());

                return SignIn(principal, OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);
            }

            throw new NotImplementedException("The specified grant type is not implemented.");
        }
    }
}