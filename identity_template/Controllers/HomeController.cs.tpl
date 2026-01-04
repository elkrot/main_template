using Microsoft.AspNetCore.Mvc;

namespace {{Namespace}}.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}