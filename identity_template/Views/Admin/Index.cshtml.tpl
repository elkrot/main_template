<!-- Views/Admin/Index.cshtml -->
@{
    ViewData["Title"] = "OpenIddict Admin";
}

<div class="container mt-4">
    <h2>OpenIddict Administration</h2>
    <div class="row">
        <div class="col-md-4">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Applications</h5>
                    <p class="card-text">Manage OAuth2/OpenID Connect applications</p>
                    <a href="@Url.Action("Index", "Applications")" class="btn btn-primary">Manage</a>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Scopes</h5>
                    <p class="card-text">Manage API scopes and resources</p>
                    <a href="#" class="btn btn-primary">Manage</a>
                </div>
            </div>
        </div>
    </div>
</div>