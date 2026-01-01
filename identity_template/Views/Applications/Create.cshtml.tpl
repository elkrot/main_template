<!-- Views/Applications/Create.cshtml -->
@model ApplicationViewModel
@{
    ViewData["Title"] = "Create Application";
}

<div class="container mt-4">
    <h2>Create Application</h2>

    <form method="post">
        <div class="form-group">
            <label asp-for="ClientId"></label>
            <input asp-for="ClientId" class="form-control" />
            <span asp-validation-for="ClientId" class="text-danger"></span>
        </div>

        <div class="form-group">
            <label asp-for="DisplayName"></label>
            <input asp-for="DisplayName" class="form-control" />
            <span asp-validation-for="DisplayName" class="text-danger"></span>
        </div>

        <div class="form-group">
            <label asp-for="ClientSecret"></label>
            <input asp-for="ClientSecret" class="form-control" />
            <span asp-validation-for="ClientSecret" class="text-danger"></span>
        </div>

        <div class="form-group">
            <label>Redirect URIs (one per line)</label>
            <textarea name="RedirectUris" class="form-control" rows="3">@string.Join("\n", Model.RedirectUris)</textarea>
        </div>

        <div class="form-group">
            <label>Post Logout Redirect URIs (one per line)</label>
            <textarea name="PostLogoutRedirectUris" class="form-control" rows="3">@string.Join("\n", Model.PostLogoutRedirectUris)</textarea>
        </div>

        <div class="form-group">
            <label>Permissions (one per line)</label>
            <textarea name="Permissions" class="form-control" rows="3">@string.Join("\n", Model.Permissions)</textarea>
        </div>

        <button type="submit" class="btn btn-primary">Create</button>
        <a href="@Url.Action("Index")" class="btn btn-secondary">Cancel</a>
    </form>
</div>