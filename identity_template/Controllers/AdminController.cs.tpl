using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace {{identitySolutionName}}.Controllers
{
// Controllers/AdminController.cs
[Authorize(Roles = "Administrator")]
[Route("admin")]
public class AdminController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}
}