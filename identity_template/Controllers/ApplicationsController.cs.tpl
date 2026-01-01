using Microsoft.AspNetCore.Mvc;
using OpenIddict.Abstractions;
using Microsoft.AspNetCore.Authorization;
using $($identitySolutionName).Models;

namespace $($identitySolutionName).Controllers
{
//Controllers/ApplicationsController.cs
[Authorize(Roles = "Administrator")]
[Route("admin/applications")]
public class ApplicationsController : Controller
{
    private readonly IOpenIddictApplicationManager _applicationManager;

    public ApplicationsController(IOpenIddictApplicationManager applicationManager)
        => _applicationManager = applicationManager;

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var applications = new List<object>();
        await foreach (var application in _applicationManager.ListAsync())
        {
            var descriptor = new OpenIddictApplicationDescriptor();
            await _applicationManager.PopulateAsync(descriptor, application);
            applications.Add(descriptor);
        }

        return View(applications);
    }

    [HttpGet("create")]
    public IActionResult Create() => View(new ApplicationViewModel());

    [HttpPost("create")]
    public async Task<IActionResult> Create(ApplicationViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        var descriptor = new OpenIddictApplicationDescriptor
        {
            ClientId = model.ClientId!,
            ClientSecret = model.ClientSecret,
            DisplayName = model.DisplayName,
        };

        foreach (var uri in model.RedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.RedirectUris.Add(new Uri(uri!));

        foreach (var uri in model.PostLogoutRedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.PostLogoutRedirectUris.Add(new Uri(uri!));

        foreach (var permission in model.Permissions.Where(p => !string.IsNullOrEmpty(p)))
            descriptor.Permissions.Add(permission!);

        foreach (var requirement in model.Requirements.Where(r => !string.IsNullOrEmpty(r)))
            descriptor.Requirements.Add(requirement!);

        await _applicationManager.CreateAsync(descriptor);

        return RedirectToAction(nameof(Index));
    }

    [HttpGet("edit/{id}")]
    public async Task<IActionResult> Edit(string id)
    {
        var application = await _applicationManager.FindByIdAsync(id);
        if (application == null)
            return NotFound();

        var descriptor = new OpenIddictApplicationDescriptor();
        await _applicationManager.PopulateAsync(descriptor, application);

        var model = new ApplicationViewModel
        {
            ClientId = descriptor.ClientId,
            DisplayName = descriptor.DisplayName,
            RedirectUris = descriptor.RedirectUris.Select(u => u.ToString()).ToList(),
            PostLogoutRedirectUris = descriptor.PostLogoutRedirectUris.Select(u => u.ToString()).ToList(),
            Permissions = descriptor.Permissions.ToList(),
            Requirements = descriptor.Requirements.ToList()
        };

        return View(model);
    }

    [HttpPost("edit/{id}")]
    public async Task<IActionResult> Edit(string id, ApplicationViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        var application = await _applicationManager.FindByIdAsync(id);
        if (application == null)
            return NotFound();

        var descriptor = new OpenIddictApplicationDescriptor();
        await _applicationManager.PopulateAsync(descriptor, application);

        descriptor.ClientId = model.ClientId!;
        descriptor.DisplayName = model.DisplayName;
        
        if (!string.IsNullOrEmpty(model.ClientSecret))
            descriptor.ClientSecret = model.ClientSecret;

        descriptor.RedirectUris.Clear();
        foreach (var uri in model.RedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.RedirectUris.Add(new Uri(uri!));

        descriptor.PostLogoutRedirectUris.Clear();
        foreach (var uri in model.PostLogoutRedirectUris.Where(u => !string.IsNullOrEmpty(u)))
            descriptor.PostLogoutRedirectUris.Add(new Uri(uri!));

        descriptor.Permissions.Clear();
        foreach (var permission in model.Permissions.Where(p => !string.IsNullOrEmpty(p)))
            descriptor.Permissions.Add(permission!);

        descriptor.Requirements.Clear();
        foreach (var requirement in model.Requirements.Where(r => !string.IsNullOrEmpty(r)))
            descriptor.Requirements.Add(requirement!);

        await _applicationManager.UpdateAsync(application, descriptor);

        return RedirectToAction(nameof(Index));
    }

    [HttpPost("delete/{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var application = await _applicationManager.FindByIdAsync(id);
        if (application != null)
        {
            await _applicationManager.DeleteAsync(application);
        }

        return RedirectToAction(nameof(Index));
    }
}
}
