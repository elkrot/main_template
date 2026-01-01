using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Mvc;
using OpenIddict.Abstractions;
using OpenIddict.Server.AspNetCore;
using System.Security.Claims;

using Microsoft.IdentityModel.Tokens;
using static OpenIddict.Abstractions.OpenIddictConstants;
using Microsoft.AspNetCore.Identity;
using MyApp.Identity.Data;
using MyApp.Identity.Models;

namespace MyApp.Identity.Controllers
{
    public class AuthorizationController : Controller
    {
        private readonly IOpenIddictApplicationManager _applicationManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;

  
        public AuthorizationController(
                   IOpenIddictApplicationManager applicationManager,
                   UserManager<ApplicationUser> userManager,
                   SignInManager<ApplicationUser> signInManager)
        {
            _applicationManager = applicationManager;
            _userManager = userManager;
            _signInManager = signInManager;
        }

        [HttpPost("~/connect/token"), Produces("application/json")]
        public async Task<IActionResult> Exchange()
        {
            var request = HttpContext.GetOpenIddictServerRequest();
            if (request.IsClientCredentialsGrantType())
            {
                // Note: the client credentials are automatically validated by OpenIddict:
                // if client_id or client_secret are invalid, this action won't be invoked.

                var application = await _applicationManager.FindByClientIdAsync(request.ClientId) ??
                    throw new InvalidOperationException("The application cannot be found.");

                // Create a new ClaimsIdentity containing the claims that
                // will be used to create an id_token, a token or a code.
                var identity = new ClaimsIdentity(TokenValidationParameters.DefaultAuthenticationType, Claims.Name, Claims.Role);

                // Use the client_id as the subject identifier.
                identity.SetClaim(Claims.Subject, await _applicationManager.GetClientIdAsync(application));
                identity.SetClaim(Claims.Name, await _applicationManager.GetDisplayNameAsync(application));

                identity.SetDestinations(static claim => claim.Type switch
                {
                    // Allow the "name" claim to be stored in both the access and identity tokens
                    // when the "profile" scope was granted (by calling principal.SetScopes(...)).
                    Claims.Name when claim.Subject.HasScope(Scopes.Profile)
                        => [Destinations.AccessToken, Destinations.IdentityToken],

                    // Otherwise, only store the claim in the access tokens.
                    _ => [Destinations.AccessToken]
                });

                return SignIn(new ClaimsPrincipal(identity), OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);
            }

            throw new NotImplementedException("The specified grant is not implemented.");
        }


        [HttpPost("~/connect/authorize"), Produces("application/json")]
        public async Task<IActionResult> Authorize([FromForm] string username, [FromForm] string password)
        {
            // Try by user name, then by email
            var user = await _userManager.FindByNameAsync(username) ?? await _userManager.FindByEmailAsync(username);
            if (user == null)
                return Unauthorized();

            var result = await _signInManager.CheckPasswordSignInAsync(user, password, lockoutOnFailure: false);
            if (!result.Succeeded)
                return Unauthorized();

            // Create principal and set claim destinations for OpenIddict
            var principal = await _signInManager.CreateUserPrincipalAsync(user);
            if (principal.Identity is ClaimsIdentity identity)
            {
                identity.SetDestinations(claim =>
                    claim.Type switch
                    {
                        Claims.Name => new[] { Destinations.AccessToken, Destinations.IdentityToken },
                        _ => new[] { Destinations.AccessToken }
                    });
            }

            // Issue token using OpenIddict's server authentication scheme
            return SignIn(principal, OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);
        }


[HttpGet("~/account/register")]
        public IActionResult Register(string returnUrl="~/")
        {
            var viewModel = new RegisterViewModel
            {
                ReturnUrl = returnUrl
            };
            return View(viewModel);
        }

        [HttpPost("~/account/register")]
        public async Task<IActionResult> Register(RegisterViewModel viewModel)
        {
            if (!ModelState.IsValid)
            {
                return View(viewModel);
            }

            var user = new ApplicationUser
            {
                UserName = viewModel.Username
            };

            var result = await _userManager.CreateAsync(user, viewModel.Password);
            if (result.Succeeded)
            {
                await _signInManager.SignInAsync(user, false);
                return Redirect(viewModel.ReturnUrl);
            }
            ModelState.AddModelError(string.Empty, "Error occurred");
            return View(viewModel);
        }

        [HttpGet("~/account/logout")]
        public async Task<IActionResult> Logout(string logoutId)
        {
            await _signInManager.SignOutAsync();
            //var logoutRequest = await _interactionService.GetLogoutContextAsync(logoutId);

            var logoutRequest = await Task.FromResult(new { PostLogoutRedirectUri = "/" }); 
            return Redirect(logoutRequest.PostLogoutRedirectUri);
        }

        [HttpGet("~/account/login")]
        public IActionResult Login(string returnUrl= "/")
        {
            var viewModel = new LoginViewModel
            {
                ReturnUrl = returnUrl
            };
            return View(viewModel);
        }

        [HttpPost("~/account/login")]
        public async Task<IActionResult> Login(LoginViewModel viewModel)
        {
            if (!ModelState.IsValid)
            {
                return View(viewModel);
            }  
            var user = await _userManager.FindByNameAsync(viewModel.Username) ??
            await _userManager.FindByEmailAsync(viewModel.Username);
            if (user == null)
                return Unauthorized();

            var result = await _signInManager.CheckPasswordSignInAsync(user, viewModel.Password, lockoutOnFailure: false);
            if (!result.Succeeded)
                return Unauthorized();

            // Create principal and set claim destinations for OpenIddict
            var principal = await _signInManager.CreateUserPrincipalAsync(user);
            if (principal.Identity is ClaimsIdentity identity)
            {
                identity.SetDestinations(claim =>
                    claim.Type switch
                    {
                        Claims.Name => new[] { Destinations.AccessToken, Destinations.IdentityToken },
                        _ => new[] { Destinations.AccessToken }
                    });
            }
            // Issue token using OpenIddict's server authentication scheme
            return SignIn(principal, OpenIddictServerAspNetCoreDefaults.AuthenticationScheme);






           
        }


    }
}